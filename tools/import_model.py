# /// script
# requires-python = ">=3.10"
# dependencies = ["torch", "torchvision"]
# ///
"""Dump a trained model's layer sequence to JSON for neural-netz to draw.

The library already derives every block's geometry from its tensor shape, so a
figure needs nothing from a model but an ordered list of (type, name, shape).
That is what this script produces. Nobody authors the topology.

Shapes come from a real forward pass rather than from reading the module tree,
because the tree does not know what a stride does. Leaf modules are hooked, a
zero tensor of the requested input size is pushed through, and each hook records
what came out of its module.

    uv run tools/import_model.py --torchvision resnet18 -o resnet18.json
    uv run tools/import_model.py --onnx yolo.onnx -o yolo.json
    uv run tools/import_model.py --checkpoint model.pt --input 1,3,512,512

The consequence of tracing leaves is that only leaf modules appear. A residual
add written as `out += identity` inside a block's forward is an operation on a
tensor, not a module, so it leaves no trace and no hook can see it. Such a model
imports as its trunk, which is the honest reading of what was observed; add the
skips by hand in the Typst file, where `connections` names layers by the same
names this file emits.
"""

from __future__ import annotations

import argparse
import importlib
import json
import sys
from pathlib import Path

# Module class name -> neural-netz layer type. Anything absent falls through to
# the rules in classify(), and --map overrides both.
TYPE_MAP = {
    "Conv1d": "conv",
    "Conv2d": "conv",
    "Conv3d": "conv",
    "ConvTranspose1d": "deconv",
    "ConvTranspose2d": "deconv",
    "ConvTranspose3d": "deconv",
    "Linear": "fc",
    "LazyLinear": "fc",
    "MaxPool1d": "pool",
    "MaxPool2d": "pool",
    "MaxPool3d": "pool",
    "AvgPool1d": "pool",
    "AvgPool2d": "pool",
    "AvgPool3d": "pool",
    "FractionalMaxPool2d": "pool",
    "Upsample": "unpool",
    "UpsamplingBilinear2d": "unpool",
    "UpsamplingNearest2d": "unpool",
    "PixelShuffle": "unpool",
    "Softmax": "softmax",
    "LogSoftmax": "softmax",
    "MultiheadAttention": "conv",
    "TransformerEncoderLayer": "conv",
    "TransformerDecoderLayer": "conv",
    "LSTM": "conv",
    "GRU": "conv",
    "RNN": "conv",
}

# Folded into the block before them rather than drawn. An activation is a
# property of the convolution that precedes it, which is exactly how the library
# already draws it, as a band on the block rather than a block of its own.
ACTIVATIONS = {
    "ReLU",
    "ReLU6",
    "LeakyReLU",
    "PReLU",
    "RReLU",
    "ELU",
    "SELU",
    "CELU",
    "GELU",
    "SiLU",
    "Mish",
    "Hardswish",
    "Hardsigmoid",
    "Sigmoid",
    "Tanh",
    "Softplus",
    "Hardtanh",
}
NORMS = {
    "BatchNorm1d",
    "BatchNorm2d",
    "BatchNorm3d",
    "GroupNorm",
    "LayerNorm",
    "InstanceNorm1d",
    "InstanceNorm2d",
    "InstanceNorm3d",
    "LocalResponseNorm",
    "SyncBatchNorm",
}
# Dropped outright: they change no shape a reader cares about.
INVISIBLE = {
    "Dropout",
    "Dropout1d",
    "Dropout2d",
    "Dropout3d",
    "Identity",
    "Flatten",
    "Unflatten",
}

# Hooked as a unit, and not descended into.
#
# Some modules dispatch to a fused kernel instead of calling their own children:
# MultiheadAttention with need_weights=False runs F.multi_head_attention_forward,
# which reaches straight into out_proj.weight rather than invoking out_proj. Its
# children therefore never fire a hook, and an attention stack imports as nothing
# at all. Hooking the container is the only way to see it.
ATOMIC = {
    "MultiheadAttention",
    "TransformerEncoderLayer",
    "TransformerDecoderLayer",
    "LSTM",
    "GRU",
    "RNN",
}


def classify(class_name: str, out_shape: list[int] | None) -> str | None:
    """Layer type for a module class, or None to drop it."""
    if class_name in TYPE_MAP:
        return TYPE_MAP[class_name]
    if class_name.startswith("Adaptive"):
        # A pool to 1x1 is a global average pool and reads better drawn as one.
        if (
            out_shape is not None
            and len(out_shape) == 3
            and out_shape[1] == 1
            and out_shape[2] == 1
        ):
            return "gap"
        return "pool"
    return None


def spatial_shape(tensor) -> list[int] | None:
    """(C, H, W) for a feature map, (F,) for a vector, None for anything else.

    The batch axis is dropped: it is not part of the architecture, and drawing a
    block whose size depends on the batch size the tracer happened to use would
    be actively misleading.
    """
    dims = list(tensor.shape)
    if len(dims) == 4:
        return [dims[1], dims[2], dims[3]]
    if len(dims) == 3:
        # (N, L, D) as produced by a transformer: tokens along one axis, width
        # along the other, which maps onto the same (channels, spatial) pair.
        return [dims[2], dims[1], 1]
    if len(dims) == 2:
        return [dims[1]]
    return None


def first_tensor(obj):
    import torch

    if isinstance(obj, torch.Tensor):
        return obj
    if isinstance(obj, (list, tuple)):
        for item in obj:
            found = first_tensor(item)
            if found is not None:
                return found
    if isinstance(obj, dict):
        for item in obj.values():
            found = first_tensor(item)
            if found is not None:
                return found
    return None


def hookable(model, atomic: set[str]):
    """Every module that should be hooked: leaves, plus atomic containers.

    A module inside an atomic one is skipped even if it is itself a leaf, so a
    fused container is counted once rather than once plus whichever of its parts
    happened to run.
    """
    chosen = []
    blocked: list[str] = []
    for path, module in model.named_modules():
        if not path:
            continue
        if any(path.startswith(prefix + ".") for prefix in blocked):
            continue
        if type(module).__name__ in atomic:
            chosen.append((path, module))
            blocked.append(path)
        elif not list(module.children()):
            chosen.append((path, module))
    return chosen


def trace(
    model, input_shape: list[int], device: str = "cpu", atomic: set[str] | None = None
) -> list[dict]:
    """Record every leaf module's output shape, in execution order."""
    import torch

    seen: list[dict] = []
    handles = []

    def make_hook(path: str, module):
        def hook(_mod, _inp, out):
            tensor = first_tensor(out)
            shape = spatial_shape(tensor) if tensor is not None else None
            seen.append(
                {
                    "path": path,
                    "op": type(module).__name__,
                    "shape": shape,
                    "params": sum(p.numel() for p in module.parameters(recurse=False)),
                }
            )

        return hook

    for path, module in hookable(model, atomic if atomic is not None else ATOMIC):
        handles.append(module.register_forward_hook(make_hook(path, module)))

    model.eval().to(device)
    with torch.no_grad():
        model(torch.zeros(*input_shape, device=device))

    for handle in handles:
        handle.remove()
    return seen


def coalesce(seen: list[dict], group_depth: int) -> list[dict]:
    """Turn traced leaves into drawable layers.

    Activations and norms fold backwards into the block they belong to;
    reshaping no-ops disappear; everything else keeps its shape and its name.
    """
    layers: list[dict] = []
    for rec in seen:
        cls = rec["op"]
        if cls in INVISIBLE:
            continue
        if cls in ACTIVATIONS or cls in NORMS:
            if layers:
                if cls in ACTIVATIONS:
                    layers[-1]["relu"] = True
                layers[-1]["folded"].append(cls)
            continue
        kind = classify(cls, rec["shape"])
        if kind is None:
            # An unrecognised module that owns weights is still a real stage and
            # is drawn as a convolution; one that owns none is plumbing.
            if rec["params"] == 0:
                continue
            kind = "conv"
        parts = rec["path"].split(".")
        layers.append(
            {
                "name": rec["path"].replace(".", "_"),
                "path": rec["path"],
                "op": cls,
                "type": kind,
                "shape": rec["shape"],
                "params": rec["params"],
                "group": ".".join(parts[:group_depth]),
                "relu": False,
                "folded": [],
            }
        )
    return layers


def collapse_repeats(layers: list[dict]) -> list[dict]:
    """Fold a run of identical adjacent layers into one with a repeat count.

    Three 512-channel convolutions at the same resolution are one idea drawn
    three times. The library stacks them behind one block, which is both shorter
    and a truer picture of the stage.
    """
    out: list[dict] = []
    for layer in layers:
        prev = out[-1] if out else None
        same = (
            prev is not None
            and prev["type"] == layer["type"]
            and prev["op"] == layer["op"]
            and prev["shape"] == layer["shape"]
            and prev["group"] == layer["group"]
        )
        if same:
            prev["repeat"] = prev.get("repeat", 1) + 1
        else:
            out.append(dict(layer))
    return out


def load_torchvision(name: str, weights: str | None):
    import torchvision.models as tvm

    factory = getattr(tvm, name, None)
    if factory is None:
        raise SystemExit(f"torchvision has no model named {name!r}")
    return factory(weights=weights) if weights else factory(weights=None)


def load_module(spec: str):
    """`package.module:callable` — anything importable that returns a model."""
    mod_name, _, attr = spec.partition(":")
    if not attr:
        raise SystemExit("--module wants package.module:callable")
    sys.path.insert(0, str(Path.cwd()))
    return getattr(importlib.import_module(mod_name), attr)()


def load_checkpoint(path: str):
    import torch

    obj = torch.load(path, map_location="cpu", weights_only=False)
    if isinstance(obj, dict):
        for key in ("model", "ema", "net"):
            if key in obj and hasattr(obj[key], "named_modules"):
                return obj[key]
        raise SystemExit(
            f"{path} holds a state dict, not a model. Rebuild the architecture and "
            "pass it with --module, or export the model to ONNX."
        )
    return obj


def from_onnx(path: str, group_depth: int) -> tuple[list[dict], dict]:
    """Read an ONNX graph instead of tracing.

    ONNX already carries inferred shapes for every intermediate value, so no
    forward pass and no input size are needed. It also has no module tree, so
    grouping falls back to the name prefix the exporter happened to write.
    """
    import onnx
    from onnx import shape_inference

    model = shape_inference.infer_shapes(onnx.load(path))
    graph = model.graph

    dims: dict[str, list[int]] = {}
    for value in list(graph.value_info) + list(graph.output) + list(graph.input):
        shape = value.type.tensor_type.shape
        got = [d.dim_value if d.HasField("dim_value") else 0 for d in shape.dim]
        if got:
            dims[value.name] = got

    onnx_types = {
        "Conv": "conv",
        "ConvTranspose": "deconv",
        "Gemm": "fc",
        "MatMul": "fc",
        "MaxPool": "pool",
        "AveragePool": "pool",
        "GlobalAveragePool": "gap",
        "Resize": "unpool",
        "Upsample": "unpool",
        "Concat": "concat",
        "Add": "sum",
        "Softmax": "softmax",
    }

    layers: list[dict] = []
    for node in graph.node:
        kind = onnx_types.get(node.op_type)
        if kind is None:
            continue
        raw = dims.get(node.output[0]) if node.output else None
        shape = None
        if raw and len(raw) == 4:
            shape = [raw[1], raw[2], raw[3]]
        elif raw and len(raw) == 2:
            shape = [raw[1]]
        name = node.name or node.output[0]
        parts = name.lstrip("/").split("/")
        layers.append(
            {
                "name": name.replace("/", "_").replace(".", "_").strip("_"),
                "path": name,
                "op": node.op_type,
                "type": kind,
                "shape": shape,
                "params": 0,
                "group": "/".join(parts[:group_depth]),
                "relu": False,
                "folded": [],
            }
        )
    meta = {"source": f"onnx:{Path(path).name}", "producer": model.producer_name}
    return layers, meta


def main() -> None:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument(
        "--torchvision",
        metavar="NAME",
        help="a torchvision.models factory, e.g. resnet18",
    )
    src.add_argument(
        "--module", metavar="pkg.mod:fn", help="importable callable returning a model"
    )
    src.add_argument(
        "--checkpoint", metavar="FILE", help="a .pt/.pth holding a whole model"
    )
    src.add_argument(
        "--onnx", metavar="FILE", help="an .onnx graph; needs no forward pass"
    )
    ap.add_argument(
        "--weights", default=None, help="torchvision weights enum, e.g. DEFAULT"
    )
    ap.add_argument(
        "--input", default="1,3,224,224", help="input shape for the traced forward pass"
    )
    ap.add_argument(
        "--group-depth", type=int, default=1, help="path components that name a stage"
    )
    ap.add_argument(
        "--collapse",
        action="store_true",
        help="fold identical adjacent layers into a repeat count",
    )
    ap.add_argument(
        "--atomic",
        default="",
        help="extra module classes to hook whole, comma separated",
    )
    ap.add_argument("--device", default="cpu")
    ap.add_argument(
        "-o", "--out", default="-", help="JSON destination, or - for stdout"
    )
    args = ap.parse_args()

    if args.onnx:
        layers, meta = from_onnx(args.onnx, args.group_depth)
    else:
        input_shape = [int(v) for v in args.input.split(",")]
        if args.torchvision:
            model = load_torchvision(args.torchvision, args.weights)
            source = f"torchvision:{args.torchvision}"
        elif args.module:
            model = load_module(args.module)
            source = args.module
        else:
            model = load_checkpoint(args.checkpoint)
            source = Path(args.checkpoint).name
        atomic = ATOMIC | {c for c in args.atomic.split(",") if c}
        layers = coalesce(
            trace(model, input_shape, args.device, atomic), args.group_depth
        )
        meta = {
            "source": source,
            "input": input_shape[1:],
            "params": sum(p.numel() for p in model.parameters()),
        }
        # The input tensor is a block in the figure but not a module in the model,
        # so it is prepended here rather than traced.
        layers.insert(
            0,
            {
                "name": "input",
                "path": "input",
                "op": "Input",
                "type": "input",
                "shape": input_shape[1:],
                "params": 0,
                "group": "input",
                "relu": False,
                "folded": [],
            },
        )

    if args.collapse:
        layers = collapse_repeats(layers)

    meta["layers"] = len(layers)
    payload = json.dumps({"meta": meta, "layers": layers}, indent=1)
    if args.out == "-":
        print(payload)
    else:
        Path(args.out).write_text(payload)
        print(
            f"{meta['source']} -> {args.out}  ({len(layers)} layers)", file=sys.stderr
        )


if __name__ == "__main__":
    main()

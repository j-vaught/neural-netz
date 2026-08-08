#import "../../src/lib.typ": draw-network, from-shapes, groups-from-shapes

#set page(width: auto, height: auto, margin: 5mm)

// ResNet-18, imported rather than authored.
//
//   uv run tools/import_model.py --torchvision resnet18 -o resnet18.json
//
// Nothing below states the architecture. The layer list, every block's size and
// every gap come from the traced shapes, and the stage brackets come from the
// module paths. Change the model and rerun the importer; the figure follows.
//
// What is written here is the part a trace cannot observe. Hooks see modules,
// and a residual add is written `out += identity` inside BasicBlock.forward, so
// it is an operation on a tensor and owns no module to hook. The eight adds are
// therefore named by hand below, from the same layer names the importer emits.
//
// The shortcut convolutions are the other half of that. They are real modules,
// so the trace does see them, but it sees them in sequence: a leaf trace has no
// way to know `downsample.0` sits beside its block rather than after it. They
// are dropped from the trunk and drawn as the projection on the skip that they
// actually are.

#let data = json("resnet18.json")

#let shortcut-color = rgb("#73000A")
#let identity-color = rgb("#466A9F")

// The 1x1 projections, which belong on the skip and not on the trunk.
#let shortcuts = ("layer2_0_downsample_0", "layer3_0_downsample_0", "layer4_0_downsample_0")

// Each residual add, as (input of the block, output of the block). The first
// block of a stage projects its shortcut; the second passes it through.
#let residual(from, to, projected) = (
  from: from, to: to, type: "skip", mode: "air", pos: auto,
  color: if projected { shortcut-color } else { identity-color },
  legend: if projected { "projected shortcut (1×1)" } else { "identity shortcut" },
)

#draw-network(
  from-shapes(data, label: "leaf", drop: shortcuts),
  groups: groups-from-shapes(data, drop: shortcuts),
  connections: (
    residual("maxpool", "layer1_0_conv2", false),
    residual("layer1_0_conv2", "layer1_1_conv2", false),
    residual("layer1_1_conv2", "layer2_0_conv2", true),
    residual("layer2_0_conv2", "layer2_1_conv2", false),
    residual("layer2_1_conv2", "layer3_0_conv2", true),
    residual("layer3_0_conv2", "layer3_1_conv2", false),
    residual("layer3_1_conv2", "layer4_0_conv2", true),
    residual("layer4_0_conv2", "layer4_1_conv2", false),
  ),
  show-legend: true,
  legend-title: "ResNet-18 (imported)",
  main-legend: "forward pass",
  show-relu: true,
)

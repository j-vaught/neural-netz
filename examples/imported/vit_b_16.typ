#import "../../src/lib.typ": draw-network, from-shapes, groups-from-shapes

#set page(width: auto, height: auto, margin: 5mm)

// ViT-B/16, imported from the pretrained torchvision checkpoint.
//
//   uv run tools/import_model.py --torchvision vit_b_16 --weights DEFAULT \
//       --group-depth 3 -o vit_b_16.json
//
// A transformer is what forced the importer to hook containers rather than only
// leaves. MultiheadAttention called with need_weights=False dispatches to a
// fused kernel that reads out_proj.weight directly instead of calling out_proj,
// so none of its children ever fire a hook, and hooking leaves alone imports a
// ViT as twelve pairs of MLP layers with the attention silently missing. The
// importer treats a handful of such modules as atomic and hooks them whole.
//
// Every block after the patch embedding carries the same 197 tokens, so the
// figure is a run of equal-height slabs whose only variation is the MLP's
// four-fold expansion. That is a fair picture of a transformer, and a much
// duller one than a convolutional pyramid.
//
// Attention and the MLP projections both import as the same layer type, since
// the library has one vocabulary for "block with learned weights". `by-op`
// separates them by the module class they came from, without naming any of the
// twenty-four blocks involved.

#let data = json("vit_b_16.json")

#let attn-color = rgb("#1F414D")

#draw-network(
  from-shapes(
    data,
    label: none,
    defaults: (label-orient: "diagonal"),
    by-op: (
      MultiheadAttention: (fill: attn-color, opacity: 0.9, legend: "Self-attention"),
      Conv2d: (legend: "Patch embedding (16×16, stride 16)"),
      Linear: (legend: "MLP projection"),
    ),
  ),
  groups: groups-from-shapes(data).map(g => (
    // The importer names each block by its module path; the bracket only needs
    // the index at the end of it.
    from: g.from, to: g.to, label: g.label.split("_").last(),
  )),
  show-legend: true,
  legend-title: "ViT-B/16 (imported)",
  main-legend: "forward pass",
  show-relu: true,
)

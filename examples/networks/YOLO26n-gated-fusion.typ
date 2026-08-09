#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// YOLO26-n with illumination-gated RGB-IR fusion.
//
// Concatenation fuses the two modalities with a fixed, learned-once recipe. But
// which modality deserves the weight is a property of the frame, not of the
// dataset: at noon the visible stream carries almost everything and the thermal
// one is washed out, and at night the ordering reverses. A gate makes the
// mixture a function of the input.
//
// A small illumination subnetwork reads a downsampled copy of the visible frame
// and emits a two-way softmax. The fusion is then a weighted sum rather than a
// concatenation, which is why no pointwise convolution follows it: a weighted
// sum preserves the channel count, so the shared backbone resumes at the stock
// width with no fold-back layer. That is the practical argument for gating over
// concatenation, and the argument against is equally plain, since a sum can only
// reweight the two streams and never combine their channels.
//
// This is the shape of the illumination-aware family in RGB-T detection, of
// which IAF R-CNN is the usual reference. The subnetwork is drawn on the trunk
// line, between the two modalities it arbitrates.

#let sppf-color = rgb("#466A9F")
#let lateral-color = rgb("#466A9F")
#let pan-color = rgb("#A49137")
#let head-feed-color = rgb("#1F414D")
#let attn-color = rgb("#65780B")
#let head-color = rgb("#CC2E40")
#let gate-color = rgb("#65780B")
#let fusion-color = rgb("#73000A")

#let lbl = (label-orient: "diagonal")

// One modality's private half-backbone: stem plus P3 stage. Both end at
// 128 channels at stride 8, which is what lets the fusion be a sum.
#let stream(p, img, label) = (
  (type: "input", image: img, shape: (3, 640, 640), label: label, channels: (3, 640), name: p + "in", label-orient: "horizontal"),
  (type: "conv", shape: (16, 320, 320), label: "P1/2", channels: (16, 320), name: p + "p1", offset: auto, ..lbl),
  (type: "conv", shape: (32, 160, 160), label: "P2/4", channels: (32, 160), name: p + "p2", offset: auto, ..lbl),
  (type: "convres", shape: (64, 160, 160), label: "C3k2", channels: (64, 160), name: p + "c2", offset: auto, ..lbl),
  (type: "conv", shape: (64, 80, 80), label: "P3/8", channels: (64, 80), name: p + "p3d", offset: auto, ..lbl),
  (type: "convres", shape: (128, 80, 80), label: "C3k2", channels: (128, 80), name: p + "p3", offset: auto, ..lbl),
)

// The gate. Deliberately tiny: it costs a rounding error next to either stem,
// which is the whole reason the trick is affordable.
#let gate = (
  (type: "input", image: "default", shape: (3, 56, 56), label: "RGB ↓56", channels: (3, 56), name: "g-in", label-orient: "horizontal"),
  (type: "conv", shape: (16, 28, 28), label: "conv", channels: (16, 28), name: "g-c1", offset: 2.2, label-orient: "horizontal", label-dy: -0.3),
  (type: "conv", shape: (32, 14, 14), label: "conv", channels: (32, 14), name: "g-c2", offset: 2.6, label-orient: "horizontal", label-dy: -0.3),
  (type: "custom", width: 0.4, height: 1.2, depth: 1.0, label: "GAP + FC", channels: (128,),
    fill: gate-color, opacity: 0.9, legend: "Illumination subnet", name: "g-fc", offset: 3.0, label-orient: "horizontal", label-dy: -0.3),
  (type: "custom", width: 0.3, height: 0.8, depth: 0.7, label: "softmax", channels: (2,),
    fill: gate-color, opacity: 0.9, show-relu: false, name: "g-w", offset: 3.4, label-orient: "horizontal", label-dy: -0.3),
)

#draw-network((
  // ---- Two modality-specific half-backbones, with the gate between them ----
  //
  // The spread is set by the labels, not by the blocks. Three streams whose
  // outer two open on a full-resolution input image leave the middle one very
  // little room, and the first thing to collide is not a block but the text
  // under one: the RGB stem's own label lands on the gate's input image, and the
  // gate's first label lands on the thermal one.
  (type: "branch", spread: 18, lead: 2.5, rejoin-lead: 3.4, branches: (
    stream("r-", "default", "RGB"),
    gate,
    stream("i-", image("bird-ir.jpg"), "IR ×3"),
  )),

  // ---- Fusion: w_rgb · F_rgb + w_ir · F_ir, at 128 channels throughout ----
  (type: "sum", label: "weighted sum", radius: 0.42, stroke: fusion-color,
    legend: "Illumination-gated sum", name: "fuse", offset: 1.6, label-orient: "horizontal"),

  // ---- Shared backbone from P4 ----
  (type: "conv", shape: (128, 40, 40), label: "P4/16", channels: (128, 40), name: "p4d", offset: 1.8, ..lbl),
  (type: "convres", shape: (256, 40, 40), label: "C3k2", channels: (256, 40), name: "p4", offset: auto, ..lbl),

  (type: "conv", shape: (256, 20, 20), label: "P5/32", channels: (256, 20), name: "p5d", offset: auto, ..lbl),
  (type: "convres", shape: (256, 20, 20), label: "C3k2", channels: (256, 20), name: "c5", offset: auto, ..lbl),

  (type: "custom", shape: (256, 20, 20), label: "SPPF", channels: (256, 20),
    fill: sppf-color, opacity: 0.9, legend: "SPPF", name: "sppf", offset: auto, ..lbl),
  (type: "custom", shape: (256, 20, 20), label: "C2PSA", channels: (256, 20),
    fill: attn-color, opacity: 0.9, legend: "C2PSA (attention)", name: "p5", offset: auto, ..lbl),

  // ---- Top-down (FPN) ----
  (type: "unpool", shape: (256, 40, 40), label: "upsample", name: "u4", offset: auto, label-orient: "horizontal", label-dx: 0.55),
  (type: "concat", shape: (384, 40, 40), name: "cat4", label: "concat", offset: auto, ..lbl),
  (type: "convres", shape: (128, 40, 40), label: "C3k2", channels: (128, 40), name: "n4", offset: auto, ..lbl),

  (type: "unpool", shape: (128, 80, 80), label: "upsample", name: "u3", offset: auto, label-orient: "horizontal", label-dx: 0.55),
  (type: "concat", shape: (192, 80, 80), name: "cat3", label: "concat", offset: auto, label-dx: 0.75, ..lbl),
  (type: "convres", shape: (64, 80, 80), label: "C3k2", channels: (64, 80), name: "n3", offset: auto, ..lbl),

  // ---- Bottom-up (PAN) ----
  (type: "conv", shape: (64, 40, 40), label: "down", channels: (64, 40), name: "d4", offset: auto, ..lbl),
  (type: "concat", shape: (192, 40, 40), name: "cat4b", label: "concat", offset: auto, label-dx: 0.5, ..lbl),
  (type: "convres", shape: (128, 40, 40), label: "C3k2", channels: (128, 40), name: "n4b", offset: auto, ..lbl),

  (type: "conv", shape: (128, 20, 20), label: "down", channels: (128, 20), name: "d5", offset: auto, ..lbl),
  (type: "concat", shape: (384, 20, 20), name: "cat5", label: "concat", offset: auto, label-dx: 0.45, ..lbl),
  (type: "convres", shape: (256, 20, 20), label: "C3k2", channels: (256, 20), name: "n5", offset: auto, ..lbl),

  // ---- Head ----
  (type: "branch", spread: 7, lead: 3.0, rejoin-lead: 4.6, spread-mode: "depth", branches: (
    ((type: "custom", width: 0.5, height: 2.6, depth: 1.4, label: "Detect P3", channels: (256, 80),
      fill: head-color, opacity: 0.9, show-relu: false, legend: "Detect (NMS-free)", name: "hp3", label-orient: "horizontal"),),
    ((type: "custom", width: 0.5, height: 2.6, depth: 1.4, label: "Detect P4", channels: (256, 40),
      fill: head-color, opacity: 0.9, show-relu: false, name: "hp4", label-orient: "horizontal"),),
    ((type: "custom", width: 0.5, height: 2.6, depth: 1.4, label: "Detect P5", channels: (256, 20),
      fill: head-color, opacity: 0.9, show-relu: false, name: "hp5", label-orient: "horizontal"),),
  )),
  (type: "output", label: "boxes + cls", height: 4, depth: 0.3, name: "out", offset: auto, ..lbl),
), groups: (
  (from: "r-in", to: "i-p3", label: "modal stems + gate"),
  (from: "p4d", to: "p4", label: "P4 stage"),
  (from: "p5d", to: "c5", label: "P5 stage"),
  (from: "sppf", to: "p5", label: "context"),
  (from: "u4", to: "n3", label: "top-down"),
  (from: "d4", to: "n5", label: "bottom-up"),
  (from: "hp5", to: "out", label: "detect"),

  (from: "r-in", to: "i-p3", label: "Backbone ×2 + illumination gate", offset: 2.5),
  (from: "p4d", to: "p5", label: "Shared backbone", offset: 2.5),
  (from: "u4", to: "n5", label: "Neck (PAN-FPN)", offset: 2.5),
  (from: "hp5", to: "out", label: "Head", offset: 2.5),
), connections: (
  (from: "p4", to: "cat4", type: "skip", mode: "air", pos: 2.6, color: lateral-color, legend: "backbone feed"),
  (from: "fuse", to: "cat3", type: "skip", mode: "air", pos: 4.0, color: lateral-color),
  (from: "n4", to: "cat4b", type: "skip", mode: "flat", pos: 4.6, color: pan-color, legend: "bottom-up feed"),
  (from: "p5", to: "cat5", type: "skip", mode: "flat", pos: 6.2, color: pan-color),
  (from: "n3", to: "hp3", type: "skip", mode: "air", pos: 4.2, color: head-feed-color, legend: "head feed"),
  (from: "n4b", to: "hp4", type: "skip", mode: "air", pos: 3.0, color: head-feed-color),
),
show-legend: true,
legend-title: "YOLO26-n · illumination-gated fusion",
main-legend: "forward pass",
show-relu: true,
)

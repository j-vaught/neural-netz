#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// YOLO26-n with multi-scale (per-level) RGB-IR fusion.
//
// Halfway fusion picks one depth and commits to it. Per-level fusion refuses
// the choice: both modalities keep a complete backbone, and the two streams are
// combined once at every pyramid level the neck consumes. Fine thermal detail
// survives at P3, where a single P3 fusion would have thrown the RGB stream's
// deeper context away, and the coarse levels still get both views.
//
// The cost is a second backbone rather than half of one, so this is the
// expensive end of feature-level fusion and the reason halfway fusion stays
// popular.
//
// Every fusion point is a concat the neck was already going to perform; the
// only structural change from the stock model is that each lateral arrives
// twice, once per modality. The two lateral families are coloured apart so the
// doubling is legible: Atlantic for the visible stream, Rose for the thermal
// one.

#let fusion-color = rgb("#73000A")
#let sppf-color = rgb("#466A9F")
#let rgb-color = rgb("#466A9F")
#let ir-color = rgb("#CC2E40")
#let pan-color = rgb("#A49137")
#let head-feed-color = rgb("#1F414D")
#let attn-color = rgb("#65780B")
#let head-color = rgb("#CC2E40")

#let lbl = (label-orient: "diagonal")

// Separation between the two backbones, and each one's offset from the trunk.
#let sep = 15
#let dy(top) = if top { sep / 2 } else { -sep / 2 }

// How a fusion lateral arrives: on the block's own edge rather than on the
// shared arrowhead in front of it, spaced evenly with whatever else lands there.
#let land = (touch-layer: true, arrive-offset: auto)

// One modality's complete backbone, through the P5 stage.
// `shift` nudges the two stage labels that a downward departure riser would
// otherwise cross. Only the thermal stream routes downward, so only it needs it.
#let backbone(p, img, label, shift: 0) = (
  (type: "input", image: img, shape: (3, 640, 640), label: label, channels: (3, 640), name: p + "in", label-orient: "horizontal"),
  (type: "conv", shape: (16, 320, 320), label: "P1/2", channels: (16, 320), name: p + "p1", offset: auto, ..lbl),
  (type: "conv", shape: (32, 160, 160), label: "P2/4", channels: (32, 160), name: p + "p2", offset: auto, ..lbl),
  (type: "convres", shape: (64, 160, 160), label: "C3k2", channels: (64, 160), name: p + "c2", offset: auto, ..lbl),

  (type: "conv", shape: (64, 80, 80), label: "P3/8", channels: (64, 80), name: p + "p3d", offset: auto, ..lbl),
  (type: "convres", shape: (128, 80, 80), label: "C3k2", channels: (128, 80), name: p + "p3", offset: auto, ..lbl),

  (type: "conv", shape: (128, 40, 40), label: "P4/16", channels: (128, 40), name: p + "p4d", offset: auto, label-dx: shift, ..lbl),
  (type: "convres", shape: (256, 40, 40), label: "C3k2", channels: (256, 40), name: p + "p4", offset: auto, ..lbl),

  (type: "conv", shape: (256, 20, 20), label: "P5/32", channels: (256, 20), name: p + "p5d", offset: auto, label-dx: shift, ..lbl),
  (type: "convres", shape: (256, 20, 20), label: "C3k2", channels: (256, 20), name: p + "p5", offset: auto, ..lbl),
)

#draw-network((
  // ---- Two complete, modality-specific backbones ----
  (type: "branch", spread: sep, lead: 2.5, branches: (
    backbone("r-", "default", "RGB"),
    backbone("i-", image("bird-ir.jpg"), "IR ×3", shift: 0.5),
  )),

  // ---- Fusion at P5: the two coarse maps meet where the branches rejoin ----
  (type: "concat", shape: (512, 20, 20), name: "f5cat", label: "concat", offset: auto, label-dx: 0.7, ..lbl),
  (type: "custom", shape: (256, 20, 20), label: "1×1 fuse P5", channels: (256, 20),
    fill: fusion-color, opacity: 0.9, legend: "Per-level fusion (1×1)", name: "f5", offset: auto, ..lbl),

  (type: "custom", shape: (256, 20, 20), label: "SPPF", channels: (256, 20),
    fill: sppf-color, opacity: 0.9, legend: "SPPF", name: "sppf", offset: auto, ..lbl),
  (type: "custom", shape: (256, 20, 20), label: "C2PSA", channels: (256, 20),
    fill: attn-color, opacity: 0.9, legend: "C2PSA (attention)", name: "c2psa", offset: auto, ..lbl),

  // ---- Top-down (FPN). Each lateral concat is a fusion point: it takes the
  // upsampled trunk plus both modalities' features at that level. ----
  (type: "unpool", shape: (256, 40, 40), label: "upsample", name: "u4", offset: auto, label-orient: "horizontal", label-dx: 0.55),
  (type: "concat", shape: (768, 40, 40), name: "cat4", label: "fuse P4", offset: auto, label-dx: -0.45, ..lbl),
  (type: "convres", shape: (128, 40, 40), label: "C3k2", channels: (128, 40), name: "n4", offset: auto, ..lbl),

  (type: "unpool", shape: (128, 80, 80), label: "upsample", name: "u3", offset: auto, label-orient: "horizontal", label-dx: 0.55),
  (type: "concat", shape: (384, 80, 80), name: "cat3", label: "fuse P3", offset: auto, label-dx: -0.45, ..lbl),
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
  (from: "r-in", to: "i-p5", label: "one backbone per modality"),
  (from: "f5cat", to: "c2psa", label: "P5 fusion + context"),
  (from: "u4", to: "n3", label: "top-down (fuses P4 and P3)"),
  (from: "d4", to: "n5", label: "bottom-up"),
  (from: "hp5", to: "out", label: "detect"),

  (from: "r-in", to: "i-p5", label: "Backbone ×2", offset: 2.5),
  (from: "f5cat", to: "n5", label: "Neck (PAN-FPN) — fusion at P5, P4, P3", offset: 2.5),
  (from: "hp5", to: "out", label: "Head", offset: 2.5),
), connections: (
  // Three things arrive at each fusion concat: the upsampled trunk and one
  // lateral per modality. Stacking three arrowheads on one anchor is what makes
  // a fan-in unreadable, so the laterals touch the block instead. The visible
  // stream routes above and lands on the top edge of the arrival face, the
  // thermal stream routes below and lands on the bottom edge, and the trunk
  // arrow keeps the middle.
  //
  // Air lanes are measured from the trunk axis, so the visible backbone's own
  // offset is folded into its lane. Flat lanes are measured from the departing
  // block, so the thermal ones need no adjustment.
  (from: "r-p4", to: "cat4", type: "skip", mode: "air", pos: 2.6 + dy(true), color: rgb-color, legend: "RGB lateral", ..land),
  (from: "r-p3", to: "cat3", type: "skip", mode: "air", pos: 4.4 + dy(true), color: rgb-color, ..land),
  (from: "i-p4", to: "cat4", type: "skip", mode: "flat", pos: 4.6, color: ir-color, legend: "IR lateral", ..land),
  (from: "i-p3", to: "cat3", type: "skip", mode: "flat", pos: 6.0, color: ir-color, ..land),

  (from: "n4", to: "cat4b", type: "skip", mode: "flat", pos: 4.6, color: pan-color, legend: "bottom-up feed"),
  (from: "c2psa", to: "cat5", type: "skip", mode: "flat", pos: 6.2, color: pan-color),
  (from: "n3", to: "hp3", type: "skip", mode: "air", pos: 4.2, color: head-feed-color, legend: "head feed"),
  (from: "n4b", to: "hp4", type: "skip", mode: "air", pos: 3.0, color: head-feed-color),
),
show-legend: true,
legend-title: "YOLO26-n · multi-scale fusion",
main-legend: "forward pass",
show-relu: true,
)

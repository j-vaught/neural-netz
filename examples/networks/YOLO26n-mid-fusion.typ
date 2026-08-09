#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// YOLO26-n with mid (feature-level) RGB-IR fusion.
//
// Each modality keeps its own stem and P3 stage, so the early filters can
// specialise: edge and colour statistics differ enough between visible and
// thermal frames that shared shallow filters serve both badly. The two P3
// maps are then concatenated and a pointwise convolution folds them back to
// the stock channel count, and everything from P4 onward is shared, which is
// the halfway-fusion recipe from the RGB-T detection literature.
//
// The neck's P3 lateral now taps the fused map rather than a single-modality
// one; the P4 lateral is downstream of the fusion and needs no change.

#let fusion-color = rgb("#73000A")
#let sppf-color = rgb("#466A9F")
#let lateral-color = rgb("#466A9F")
#let pan-color = rgb("#A49137")
#let head-feed-color = rgb("#1F414D")
#let attn-color = rgb("#65780B")
#let head-color = rgb("#CC2E40")

#let lbl = (label-orient: "diagonal")

// One modality's private half-backbone: stem plus P3 stage.
#let stream(prefix, img, label) = (
  (type: "input", image: img, shape: (3, 640, 640), label: label, channels: (3, 640), name: prefix + "-in", label-orient: "horizontal"),
  (type: "conv", shape: (16, 320, 320), label: "P1/2", channels: (16, 320), name: prefix + "-p1", offset: auto, ..lbl),
  (type: "conv", shape: (32, 160, 160), label: "P2/4", channels: (32, 160), name: prefix + "-p2", offset: auto, ..lbl),
  (type: "convres", shape: (64, 160, 160), label: "C3k2", channels: (64, 160), name: prefix + "-c2", offset: auto, ..lbl),
  (type: "conv", shape: (64, 80, 80), label: "P3/8", channels: (64, 80), name: prefix + "-p3d", offset: auto, ..lbl),
  (type: "convres", shape: (128, 80, 80), label: "C3k2", channels: (128, 80), name: prefix + "-p3", offset: auto, ..lbl),
)

#draw-network((
  // ---- Two modality-specific half-backbones ----
  (type: "branch", spread: 13, lead: 2.5, branches: (
    stream("rgb", "default", "RGB"),
    stream("ir", image("bird-ir.jpg"), "IR ×3"),
  )),

  // ---- Mid fusion: concat the two P3 maps, fold back to stock width ----
  (type: "concat", shape: (256, 80, 80), name: "fcat", label: "concat", offset: auto, label-dx: 0.7, ..lbl),
  (type: "custom", shape: (128, 80, 80), label: "1×1 fuse", channels: (128, 80),
    fill: fusion-color, opacity: 0.9, legend: "Mid fusion (1×1)", name: "f3", offset: auto, ..lbl),

  // ---- Shared backbone from P4 ----
  (type: "conv", shape: (128, 40, 40), label: "P4/16", channels: (128, 40), name: "p4d", offset: auto, ..lbl),
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
  (type: "concat", shape: (192, 80, 80), name: "cat3", label: "concat", offset: auto, ..lbl),
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
  (from: "rgb-in", to: "rgb-p3", label: "modal stems + P3"),
  (from: "fcat", to: "f3", label: "mid fusion"),
  (from: "p4d", to: "p4", label: "P4 stage"),
  (from: "p5d", to: "c5", label: "P5 stage"),
  (from: "sppf", to: "p5", label: "context"),
  (from: "u4", to: "n3", label: "top-down"),
  (from: "d4", to: "n5", label: "bottom-up"),
  (from: "hp5", to: "out", label: "detect"),

  (from: "rgb-in", to: "rgb-p3", label: "Backbone ×2", offset: 2.5),
  (from: "fcat", to: "p5", label: "Fusion + shared backbone", offset: 2.5),
  (from: "u4", to: "n5", label: "Neck (PAN-FPN)", offset: 2.5),
  (from: "hp5", to: "out", label: "Head", offset: 2.5),
), connections: (
  (from: "p4", to: "cat4", type: "skip", mode: "air", pos: 2.6, color: lateral-color, legend: "backbone feed"),
  (from: "f3", to: "cat3", type: "skip", mode: "air", pos: 4.0, color: lateral-color),
  (from: "n4", to: "cat4b", type: "skip", mode: "flat", pos: 4.6, color: pan-color, legend: "bottom-up feed"),
  (from: "p5", to: "cat5", type: "skip", mode: "flat", pos: 6.2, color: pan-color),
  (from: "n3", to: "hp3", type: "skip", mode: "air", pos: 4.2, color: head-feed-color, legend: "head feed"),
  (from: "n4b", to: "hp4", type: "skip", mode: "air", pos: 3.0, color: head-feed-color),
),
show-legend: true,
legend-title: "YOLO26-n · mid fusion",
main-legend: "forward pass",
show-relu: true,
)

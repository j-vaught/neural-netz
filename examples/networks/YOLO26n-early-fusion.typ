#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// YOLO26-n with early (pixel-level) RGB-IR fusion.
//
// The two modalities merge before the network proper. The IR frame is a single
// channel replicated across three, so both inputs arrive as (3, 640, 640); a
// concat stacks them to six channels and a pointwise convolution mixes them
// back down to three. From P1 onward the figure is the stock YOLO26-n, and the
// fused tensor is shaped exactly like an RGB frame, which is the point of
// fusing this early: nothing downstream knows there were two sensors.

#let fusion-color = rgb("#73000A")
#let sppf-color = rgb("#466A9F")
#let lateral-color = rgb("#466A9F")
#let pan-color = rgb("#A49137")
#let head-feed-color = rgb("#1F414D")
#let attn-color = rgb("#65780B")
#let head-color = rgb("#CC2E40")

#let lbl = (label-orient: "diagonal")

#draw-network((
  // ---- Early fusion: two sensors, one tensor ----
  (type: "branch", spread: 13, lead: 2.5, branches: (
    ((type: "input", image: "default", shape: (3, 640, 640), label: "RGB", channels: (3, 640), name: "rgb", label-orient: "horizontal"),),
    ((type: "input", image: image("bird-ir.jpg"), shape: (3, 640, 640), label: "IR ×3", channels: (3, 640), name: "ir", label-orient: "horizontal"),),
  )),
  (type: "concat", shape: (6, 640, 640), name: "fcat", label: "concat", offset: auto, label-dx: 0.7, ..lbl),
  (type: "custom", shape: (3, 640, 640), label: "1×1 mix", channels: (3, 640),
    fill: fusion-color, opacity: 0.9, legend: "Early fusion (1×1 mix)", name: "mix", offset: auto, ..lbl),

  // ---- Backbone ----
  (type: "conv", shape: (16, 320, 320), label: "P1/2", channels: (16, 320), name: "p1", offset: auto, ..lbl),
  (type: "conv", shape: (32, 160, 160), label: "P2/4", channels: (32, 160), name: "p2", offset: auto, ..lbl),
  (type: "convres", shape: (64, 160, 160), label: "C3k2", channels: (64, 160), name: "c2", offset: auto, ..lbl),

  (type: "conv", shape: (64, 80, 80), label: "P3/8", channels: (64, 80), name: "p3d", offset: auto, ..lbl),
  (type: "convres", shape: (128, 80, 80), label: "C3k2", channels: (128, 80), name: "p3", offset: auto, ..lbl),

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
  (from: "rgb", to: "mix", label: "early fusion"),
  (from: "p1", to: "c2", label: "stem"),
  (from: "p3d", to: "p3", label: "P3 stage"),
  (from: "p4d", to: "p4", label: "P4 stage"),
  (from: "p5d", to: "c5", label: "P5 stage"),
  (from: "sppf", to: "p5", label: "context"),
  (from: "u4", to: "n3", label: "top-down"),
  (from: "d4", to: "n5", label: "bottom-up"),
  (from: "hp5", to: "out", label: "detect"),

  (from: "rgb", to: "mix", label: "Fusion", offset: 2.5),
  (from: "p1", to: "p5", label: "Backbone", offset: 2.5),
  (from: "u4", to: "n5", label: "Neck (PAN-FPN)", offset: 2.5),
  (from: "hp5", to: "out", label: "Head", offset: 2.5),
), connections: (
  (from: "p4", to: "cat4", type: "skip", mode: "air", pos: 2.6, color: lateral-color, legend: "backbone feed"),
  (from: "p3", to: "cat3", type: "skip", mode: "air", pos: 4.0, color: lateral-color),
  (from: "n4", to: "cat4b", type: "skip", mode: "flat", pos: 4.6, color: pan-color, legend: "bottom-up feed"),
  (from: "p5", to: "cat5", type: "skip", mode: "flat", pos: 6.2, color: pan-color),
  (from: "n3", to: "hp3", type: "skip", mode: "air", pos: 4.2, color: head-feed-color, legend: "head feed"),
  (from: "n4b", to: "hp4", type: "skip", mode: "air", pos: 3.0, color: head-feed-color),
),
show-legend: true,
legend-title: "YOLO26-n · early fusion",
main-legend: "forward pass",
show-relu: true,
)

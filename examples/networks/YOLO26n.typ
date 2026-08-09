#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// YOLO26-n : depth 0.50, width 0.25, max_channels 1024
//
// Nothing in this figure is sized or spaced by hand. Each layer states its
// tensor shape and takes its geometry from that, and every offset is auto, which
// covers the previous block's isometric lean and widens where a connection
// descends into the gap.
//
// So the architecture is the only thing written down. Change a channel count or
// a resolution and the drawing follows, with no second copy of the pyramid in
// the offsets to drift out of step.
//
// Labels are diagonal, which is what lets the gaps stay this tight: with
// horizontal labels the spacing ends up dictated by how wide the words are
// rather than by the drawing.
//
// Groups are drawn in two rows, one naming each stage and one naming the three
// parts anyone says out loud. Both are below the figure, clear of the skips that
// route underneath it.

#let sppf-color = rgb("#466A9F")
#let lateral-color = rgb("#466A9F")
#let pan-color = rgb("#A49137")
#let head-feed-color = rgb("#1F414D")
#let attn-color = rgb("#65780B")
#let head-color = rgb("#CC2E40")

#let lbl = (label-orient: "diagonal")

#draw-network((
  (type: "input", image: "default", shape: (3, 640, 640), label: "input", channels: (3, 640), name: "input", ..lbl),

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
  // Three heads drawn as three heads, stacked along the depth axis: P4 on the
  // trunk line, P3 away, P5 near. Sized alike rather than from shape, since a
  // head is a module reading a level, not a feature map, and letting each take
  // its level's resolution makes the P3 one tower over the figure.
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
  // Two levels. The inner row names each stage, the outer row the three parts
  // anyone says out loud when explaining the architecture. Nesting works because
  // offset is per group, so an enclosing bracket simply takes its own row.
  (from: "p1", to: "c2", label: "stem"),
  (from: "p3d", to: "p3", label: "P3 stage"),
  (from: "p4d", to: "p4", label: "P4 stage"),
  (from: "p5d", to: "c5", label: "P5 stage"),
  (from: "sppf", to: "p5", label: "context"),
  (from: "u4", to: "n3", label: "top-down"),
  (from: "d4", to: "n5", label: "bottom-up"),
  (from: "hp5", to: "out", label: "detect"),

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
legend-title: "YOLO26-n",
main-legend: "forward pass",
show-relu: true,
)

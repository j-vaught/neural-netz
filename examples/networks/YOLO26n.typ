#import "../../src/lib.typ": draw-network, depth-shear, min-clear-offset

#set page(width: auto, height: auto, margin: 5mm)

// YOLO26-n : depth 0.50, width 0.25, max_channels 1024
//
// Every gap in this figure is computed from the geometry rather than tuned by
// eye. Two rules cover all of them, and both take the depth of the block being
// stepped away from:
//
//   sep(d)    leave a constant strip of white space after a block. The offset
//             has to cover the block's own lean first, or the next block is
//             drawn on top of it.
//
//   clear(d)  the same, but wide enough that a connection descending into the
//             gap arrives clear of the block's sheared top face. Used before
//             every concat, and before the head, since those are the only
//             places a connection comes down.
//
// Change a stage's depth and its spacing follows. Labels are diagonal, which is
// what lets the gaps stay this tight: with horizontal labels the spacing ends up
// dictated by how wide the words are rather than by the drawing.
//
// Groups are drawn in two rows, one naming each stage and one naming the three
// parts anyone says out loud. Both are below the figure, clear of the skips that
// route underneath it.

// ---- the pyramid, in one place ----
#let d-in = 8      // 640
#let d-p1 = 7      // 320
#let d-p2 = 6      // 160
#let d-p3 = 4.5    // 80
#let d-p4 = 3      // 40
#let d-p5 = 2      // 20

// Visible white space to leave between blocks, before the lean is added on.
#let vis = 0.55

#let sep(d) = depth-shear(d) + vis
#let clear(d) = calc.max(min-clear-offset(d), sep(d))

#let sppf-color = rgb("#466A9F")
#let attn-color = rgb("#65780B")
#let head-color = rgb("#CC2E40")

#let lbl = (label-orient: "diagonal")

#draw-network((
  (type: "input", image: "default", height: d-in, depth: d-in, label: "input", channels: (3, 640), name: "input", ..lbl),

  // ---- Backbone ----
  (type: "conv", widths: (0.3,), height: d-p1, depth: d-p1, label: "P1/2", channels: (16, 320), name: "p1", offset: sep(d-in), ..lbl),
  (type: "conv", widths: (0.3,), height: d-p2, depth: d-p2, label: "P2/4", channels: (32, 160), name: "p2", offset: sep(d-p1), ..lbl),
  (type: "convres", widths: (0.4,), height: d-p2, depth: d-p2, label: "C3k2", channels: (64, 160), name: "c2", offset: sep(d-p2), ..lbl),

  (type: "conv", widths: (0.3,), height: d-p3, depth: d-p3, label: "P3/8", channels: (64, 80), name: "p3d", offset: sep(d-p2), ..lbl),
  (type: "convres", widths: (0.5,), height: d-p3, depth: d-p3, label: "C3k2", channels: (128, 80), name: "p3", offset: sep(d-p3), ..lbl),

  (type: "conv", widths: (0.3,), height: d-p4, depth: d-p4, label: "P4/16", channels: (128, 40), name: "p4d", offset: sep(d-p3), ..lbl),
  (type: "convres", widths: (0.6,), height: d-p4, depth: d-p4, label: "C3k2", channels: (256, 40), name: "p4", offset: sep(d-p4), ..lbl),

  (type: "conv", widths: (0.3,), height: d-p5, depth: d-p5, label: "P5/32", channels: (256, 20), name: "p5d", offset: sep(d-p4), ..lbl),
  (type: "convres", widths: (0.6,), height: d-p5, depth: d-p5, label: "C3k2", channels: (256, 20), name: "c5", offset: sep(d-p5), ..lbl),

  (type: "custom", width: 0.6, height: d-p5, depth: d-p5, label: "SPPF", channels: (256, 20),
    fill: sppf-color, opacity: 0.9, legend: "SPPF", name: "sppf", offset: sep(d-p5), ..lbl),
  (type: "custom", width: 0.6, height: d-p5, depth: d-p5, label: "C2PSA", channels: (256, 20),
    fill: attn-color, opacity: 0.9, legend: "C2PSA (attention)", name: "p5", offset: sep(d-p5), ..lbl),

  // ---- Top-down (FPN) ----
  (type: "unpool", height: d-p4, depth: d-p4, label: "up x2", name: "u4", offset: sep(d-p5), ..lbl),
  (type: "concat", height: d-p4, depth: d-p4, name: "cat4", offset: clear(d-p4)),
  (type: "convres", widths: (0.5,), height: d-p4, depth: d-p4, label: "C3k2", channels: (128, 40), name: "n4", offset: sep(d-p4), ..lbl),

  (type: "unpool", height: d-p3, depth: d-p3, label: "up x2", name: "u3", offset: sep(d-p4), ..lbl),
  (type: "concat", height: d-p3, depth: d-p3, name: "cat3", offset: clear(d-p3)),
  (type: "convres", widths: (0.4,), height: d-p3, depth: d-p3, label: "C3k2", channels: (64, 80), name: "n3", offset: sep(d-p3), ..lbl),

  // ---- Bottom-up (PAN) ----
  (type: "conv", widths: (0.3,), height: d-p4, depth: d-p4, label: "down", channels: (64, 40), name: "d4", offset: sep(d-p3), ..lbl),
  (type: "concat", height: d-p4, depth: d-p4, name: "cat4b", offset: clear(d-p4)),
  (type: "convres", widths: (0.5,), height: d-p4, depth: d-p4, label: "C3k2", channels: (128, 40), name: "n4b", offset: sep(d-p4), ..lbl),

  (type: "conv", widths: (0.3,), height: d-p5, depth: d-p5, label: "down", channels: (128, 20), name: "d5", offset: sep(d-p4), ..lbl),
  (type: "concat", height: d-p5, depth: d-p5, name: "cat5", offset: clear(d-p5)),
  (type: "convres", widths: (0.6,), height: d-p5, depth: d-p5, label: "C3k2", channels: (256, 20), name: "n5", offset: sep(d-p5), ..lbl),

  // ---- Head ----
  // Two connections come down here, not one, so widen past the bare minimum.
  (type: "custom", width: 0.7, height: 5, depth: d-p5, label: "Detect", channels: ("P3 / P4 / P5",),
    fill: head-color, opacity: 0.9, show-relu: false, legend: "Detect (NMS-free)", name: "head",
    offset: clear(d-p5) + 1.4, ..lbl),
  (type: "output", label: "boxes + cls", height: 4, depth: 0.3, name: "out", offset: sep(d-p5), ..lbl),
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
  (from: "head", to: "out", label: "detect"),

  (from: "p1", to: "p5", label: "Backbone", offset: 2.5, color: rgb("#73000A")),
  (from: "u4", to: "n5", label: "Neck (PAN-FPN)", offset: 2.5, color: rgb("#73000A")),
  (from: "head", to: "out", label: "Head", offset: 2.5, color: rgb("#73000A")),
), connections: (
  (from: "p4", to: "cat4", type: "skip", mode: "air", pos: 2.6),
  (from: "p3", to: "cat3", type: "skip", mode: "air", pos: 4.0),
  (from: "n4", to: "cat4b", type: "skip", mode: "flat", pos: 4.6),
  (from: "p5", to: "cat5", type: "skip", mode: "flat", pos: 6.2),
  (from: "n3", to: "head", type: "skip", mode: "air", pos: 5.2, label: "P3"),
  (from: "n4b", to: "head", type: "skip", mode: "air", pos: 2.0, label: "P4"),
),
show-legend: true,
legend-title: "YOLO26-n",
show-relu: true,
)

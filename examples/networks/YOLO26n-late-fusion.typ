#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// YOLO26-n with late (decision-level) RGB-IR fusion.
//
// Two complete, unmodified YOLO26-n detectors run side by side, one on the
// RGB frame and one on the IR frame replicated across three channels so the
// stock 3-channel stem ingests it unchanged. Nothing is shared and nothing is
// retrained jointly, which is the appeal of late fusion: either detector can
// be swapped or run alone.
//
// Each stream is drawn compressed, one block per backbone stage with its
// C3k2 folded in, and the whole PAN-FPN neck as a single module fed by the
// P3, P4 and P5 maps. The interpretation step at the end is Weighted Box
// Fusion: both streams emit their own NMS-free box list, and WBF merges
// overlapping boxes by confidence-weighted averaging rather than picking a
// winner, so agreement between modalities raises a box's score instead of
// discarding the duplicate.

#let fusion-color = rgb("#73000A")
#let ctx-color = rgb("#466A9F")
#let feed-color = rgb("#1F414D")
#let neck-color = rgb("#A49137")
#let head-color = rgb("#CC2E40")

#let lbl = (label-orient: "diagonal")

// One complete detector, compressed: each stage block carries its C3k2, the
// context pair is one module, and the whole neck is one module.
#let detector(prefix, img, label) = (
  (type: "input", image: img, shape: (3, 640, 640), label: label, channels: (3, 640), name: prefix + "-in", label-orient: "horizontal"),
  (type: "conv", shape: (16, 320, 320), label: "P1/2", channels: (16, 320), name: prefix + "-p1", offset: auto, ..lbl),
  (type: "conv", shape: (32, 160, 160), label: "P2/4 · C3k2", channels: (64, 160), name: prefix + "-p2", offset: auto, ..lbl),
  (type: "convres", shape: (128, 80, 80), label: "P3/8 · C3k2", channels: (128, 80), name: prefix + "-p3", offset: auto, ..lbl),
  (type: "convres", shape: (256, 40, 40), label: "P4/16 · C3k2", channels: (256, 40), name: prefix + "-p4", offset: auto, ..lbl),
  (type: "convres", shape: (256, 20, 20), label: "P5/32 · C3k2", channels: (256, 20), name: prefix + "-p5", offset: auto, ..lbl),
  (type: "custom", shape: (256, 20, 20), label: "SPPF · C2PSA", channels: (256, 20),
    fill: ctx-color, opacity: 0.9, legend: "SPPF + C2PSA", name: prefix + "-ctx", offset: auto, ..lbl),
  (type: "custom", width: 1.0, height: 4.5, depth: 3, label: "PAN-FPN",
    fill: neck-color, opacity: 0.9, show-relu: false, legend: "PAN-FPN neck", name: prefix + "-neck", offset: 2.0,
    label-dx: -0.8, ..lbl),
  (type: "custom", width: 0.5, height: 3, depth: 1.4, label: "Detect ×3",
    fill: head-color, opacity: 0.9, show-relu: false, legend: "Detect (NMS-free)", name: prefix + "-det", offset: auto, label-orient: "horizontal"),
  (type: "output", label: "boxes + cls", height: 3.5, depth: 0.3, name: prefix + "-out", offset: auto, ..lbl),
)

#draw-network((
  // ---- Two full detectors, one per modality ----
  (type: "branch", spread: 15, lead: 2.5, rejoin-lead: 3.0, branches: (
    detector("rgb", "default", "RGB"),
    detector("ir", image("bird-ir.jpg"), "IR ×3"),
  )),

  // ---- Decision fusion: merge the two box lists ----
  (type: "custom", width: 0.9, height: 4, depth: 1.6, label: "WBF",
    fill: fusion-color, opacity: 0.9, show-relu: false, legend: "Weighted Box Fusion", name: "wbf", offset: auto, label-orient: "horizontal"),
  (type: "output", label: "fused boxes + cls", height: 4, depth: 0.3, name: "out", offset: auto, ..lbl),
), groups: (
  (from: "rgb-in", to: "rgb-out", label: "YOLO26-n ×2 — one detector per modality"),
  (from: "wbf", to: "out", label: "late fusion (decision level)"),
), connections: (
  // Multi-scale feeds into each stream's neck: P3 and P4 by skip, P5 down the trunk.
  (from: "rgb-p3", to: "rgb-neck", type: "skip", mode: "air", pos: 13.0, touch-layer: true, arrive-offset: 0.9, color: feed-color, legend: "multi-scale feed"),
  (from: "rgb-p4", to: "rgb-neck", type: "skip", mode: "air", pos: 11.3, touch-layer: true, arrive-offset: -0.9, color: feed-color),
  (from: "ir-p3", to: "ir-neck", type: "skip", mode: "flat", pos: 6.2, touch-layer: true, arrive-offset: 0.9, color: feed-color),
  (from: "ir-p4", to: "ir-neck", type: "skip", mode: "flat", pos: 4.7, touch-layer: true, arrive-offset: -0.9, color: feed-color),
),
show-legend: true,
legend-title: "YOLO26-n · late fusion",
main-legend: "forward pass",
show-relu: true,
)

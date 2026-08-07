#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 1.2 -- label-anchor and label-dx.
//
// label-anchor chooses which edge of the text box is pinned to the label
// position, so a label can be hung off to one side instead of centred. Combined
// with label-dx it fans crowded labels sideways rather than vertically.
//
// Both rows have identical geometry. The second pins the outer labels by their
// facing edges and pushes them clear of the middle one.

#let row(a, b, c) = (
  (type: "conv", widths: (0.3,), height: 3, depth: 3, label: "convolution", ..a),
  (type: "conv", widths: (0.3,), height: 3, depth: 3, label: "downsample", offset: 0.4, ..b),
  (type: "conv", widths: (0.3,), height: 3, depth: 3, label: "projection", offset: 0.4, ..c),
)

// Centred on each layer, the default.
#draw-network(row((:), (:), (:)))

#v(6mm)

// Outer labels anchored by their inner edges and pushed outward.
#draw-network(row(
  (label-anchor: "base-east", label-dx: -0.3),
  (:),
  (label-anchor: "base-west", label-dx: 0.3),
))

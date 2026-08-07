#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 1.2 -- label-angle.
//
// Shifting labels apart only buys so much room; past a certain density the
// labels simply do not fit side by side at any vertical offset. Rotating them
// trades horizontal space, which is what is scarce, for vertical space, which
// is usually free below the figure.
//
// All three rows have identical geometry and identical labels. Only the angle
// differs.

#let row(a) = (
  (type: "conv", widths: (0.3,), height: 3, depth: 3, label: "convolution", ..a),
  (type: "conv", widths: (0.3,), height: 3, depth: 3, label: "downsample", offset: 0.4, ..a),
  (type: "conv", widths: (0.3,), height: 3, depth: 3, label: "projection", offset: 0.4, ..a),
  (type: "conv", widths: (0.3,), height: 3, depth: 3, label: "bottleneck", offset: 0.4, ..a),
)

// Horizontal: unreadable at this spacing.
#draw-network(row((:)))

#v(8mm)

// 45 degrees, anchored east so the labels hang back from their layers.
#draw-network(row((label-angle: 45deg, label-anchor: "base-east")))

#v(8mm)

// 90 degrees, fully vertical.
#draw-network(row((label-angle: 90deg, label-anchor: "base-east")))

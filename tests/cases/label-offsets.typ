#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 1.2 -- label-dy.
//
// Layer labels are placed at a fixed spot beneath each block with no awareness
// of their neighbours, so long labels on tightly spaced layers overlap. Before
// this feature the only remedy was to push the layers themselves further apart,
// which distorts the figure to solve a typesetting problem.
//
// Both rows below have identical geometry. The only difference is label-dy on
// the middle layer of the second row.

#let row(mid) = (
  (type: "conv", widths: (0.3,), height: 3, depth: 3, label: "convolution"),
  (type: "conv", widths: (0.3,), height: 3, depth: 3, label: "downsample", offset: 0.58, ..mid),
  (type: "conv", widths: (0.3,), height: 3, depth: 3, label: "projection", offset: 0.58),
)

// Collides: three labels compete for the same band of space.
#draw-network(row((:)))

#v(6mm)

// Resolved: only the middle label moves, the layers do not.
#draw-network(row((label-dy: -0.55)))

#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 1.2 -- label-orient.
//
// The three orientations anyone actually reaches for, each paired with the
// anchor that places it correctly against its layer. Nothing here sets
// label-anchor or label-dx: the point of this option is that the common cases
// need no manual adjustment.
//
// For any other angle, use label-angle and choose label-anchor yourself. Setting
// both label-orient and label-angle is an error.

#let row(o) = (
  (type: "conv", widths: (0.3,), height: 3, depth: 3, label: "convolution", ..o),
  (type: "conv", widths: (0.3,), height: 3, depth: 3, label: "downsample", offset: 0.4, ..o),
  (type: "conv", widths: (0.3,), height: 3, depth: 3, label: "projection", offset: 0.4, ..o),
  (type: "conv", widths: (0.3,), height: 3, depth: 3, label: "bottleneck", offset: 0.4, ..o),
)

// horizontal (the default): unreadable at this spacing, shown for comparison.
#draw-network(row((label-orient: "horizontal")))

#v(8mm)

// diagonal: each label's end points at its own layer.
#draw-network(row((label-orient: "diagonal")))

#v(8mm)

// vertical: each label hangs centred beneath its own layer.
#draw-network(row((label-orient: "vertical")))

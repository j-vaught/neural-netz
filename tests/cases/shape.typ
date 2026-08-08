#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 3.11 -- shape.
//
// A layer may state its tensor shape as (channels, height, width) and have its
// geometry derived, rather than being sized by eye.
//
// Both axes are logarithmic:
//   height, depth = 1.2 * log2(spatial) - 3.2
//   width         = 0.075 * log2(channels)
//
// Linear spatial extent is unusable. Against the pyramid below a 20-square block
// would be a quarter of a unit tall against 8 for the 640-square input. The log
// mapping reproduces the same pyramid tuned by hand elsewhere in this repo to
// within 0.4 units, and the channel mapping its widths to within 0.05.

// Derived and hand-written, side by side. The second block spells out the
// mapping rather than rounding it, so the two are pixel-identical: rounding the
// height to 3.186 instead of 3.18631... is already enough to shift the edges by
// a fraction of a pixel and show up in a diff.
#let hd = 1.2 * calc.log(40, base: 2) - 3.2
#let wd = 0.075 * calc.log(256, base: 2)
#draw-network((
  (type: "conv", shape: (256, 40, 40), label: "shape"),
  (type: "conv", height: hd, depth: hd, widths: (wd,), label: "by hand", offset: 1.6),
))

#v(9mm)

// A pyramid spanning 640 down to 20, an order of magnitude and a half, with no
// sizes given anywhere.
#draw-network((
  (type: "conv", shape: (3, 640, 640), label: "640"),
  (type: "conv", shape: (16, 320, 320), label: "320", offset: 1.4),
  (type: "conv", shape: (64, 160, 160), label: "160", offset: 1.4),
  (type: "convres", shape: (128, 80, 80), label: "80", offset: 1.4),
  (type: "convres", shape: (256, 40, 40), label: "40", offset: 1.4),
  (type: "convres", shape: (512, 20, 20), label: "20", offset: 1.4),
))

#v(9mm)

// Shape supplies defaults, not values, so manual control survives field by
// field. All three below share one shape and differ only in what they override.
#draw-network((
  (type: "conv", shape: (256, 40, 40), label: "all derived"),
  (type: "conv", shape: (256, 40, 40), height: 5, label: "height forced", offset: 1.8),
  (type: "conv", shape: (256, 40, 40), widths: (1.2,), label: "width forced", offset: 1.8),
))

#v(9mm)

// Non-square feature maps: height and depth come from the two spatial extents
// independently.
#draw-network((
  (type: "conv", shape: (64, 320, 80), label: "320 x 80"),
  (type: "conv", shape: (64, 80, 320), label: "80 x 320", offset: 2.0),
))

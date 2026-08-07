#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 3.9 -- arrive-offset.
//
// touch-layer lands a route on the target layer itself rather than on the axis
// in front of it, choosing a side from the routing mode: air arrives on the top
// edge, flat on the bottom, depth on the left. Two routes in the same mode
// therefore landed on the identical pixel, with their arrowheads stacked.
//
// arrive-offset spreads along whichever edge the mode already chose. It runs
// along the edge rather than in x, since the top and bottom edges of the west
// side follow the isometric depth direction: offsetting horizontally would walk
// the arrival off the block.

#let src(n) = (
  type: "conv", widths: (0.3,), height: 2.5, depth: 2.5,
  name: "s" + str(n), label: "s" + str(n), offset: 1.1,
)

#let cat = (type: "concat", height: 3.2, depth: 3.2, name: "cat", label: "concat", offset: 2.6)

// Without offsets: three routes, one arrival point, arrowheads on top of one
// another.
#draw-network(
  (src(1), src(2), src(3), cat),
  connections: (
    (from: "s1", to: "cat", touch-layer: true, pos: auto),
    (from: "s2", to: "cat", touch-layer: true, pos: auto),
    (from: "s3", to: "cat", touch-layer: true, pos: auto),
  ),
)

#v(9mm)

// With offsets: the same three routes fan across the top edge.
#draw-network(
  (src(1), src(2), src(3), cat),
  connections: (
    (from: "s1", to: "cat", touch-layer: true, pos: auto, arrive-offset: -0.35),
    (from: "s2", to: "cat", touch-layer: true, pos: auto, arrive-offset: 0),
    (from: "s3", to: "cat", touch-layer: true, pos: auto, arrive-offset: 0.35),
  ),
)

#v(9mm)

// The other two sides. flat arrives on the bottom edge and offsets along it,
// depth arrives on the left edge and offsets vertically.
#draw-network(
  (src(1), src(2), src(3), src(4), cat),
  connections: (
    (from: "s1", to: "cat", touch-layer: true, mode: "flat", pos: auto,
      arrive-offset: -0.35, color: rgb("#73000A"), legend: "flat, -0.35"),
    (from: "s2", to: "cat", touch-layer: true, mode: "flat", pos: auto,
      arrive-offset: 0.35, color: rgb("#466A9F"), legend: "flat, +0.35"),
    (from: "s3", to: "cat", touch-layer: true, mode: "depth", pos: 1.0,
      arrive-offset: -0.5, color: rgb("#65780B"), legend: "depth, -0.5"),
    (from: "s4", to: "cat", touch-layer: true, mode: "depth", pos: 1.8,
      arrive-offset: 0.5, color: rgb("#A49137"), legend: "depth, +0.5"),
  ),
  show-legend: true,
  legend-title: "Arrivals",
)

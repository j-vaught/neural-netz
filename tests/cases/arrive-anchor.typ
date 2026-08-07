#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 3.9 -- arrive-offset.
//
// touch-layer lands a route on the target layer itself rather than on the axis
// in front of it, choosing a side from the routing mode: air arrives on the top
// edge, flat on the bottom, depth on the left. Without an offset, two routes in
// the same mode land on the identical point with their arrowheads stacked.
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

// Three routes fanning onto the top edge. flat and depth arrivals use the same
// offset-along-the-edge code with a different edge chosen by touch-layer, so
// they are not drawn again here.
#draw-network(
  (src(1), src(2), src(3), cat),
  connections: (
    (from: "s1", to: "cat", touch-layer: true, pos: auto, arrive-offset: -0.35),
    (from: "s2", to: "cat", touch-layer: true, pos: auto, arrive-offset: 0),
    (from: "s3", to: "cat", touch-layer: true, pos: auto, arrive-offset: 0.35),
  ),
)

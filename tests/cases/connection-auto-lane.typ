#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 2.10 (partial) -- pos: auto.
//
// pos is measured from the centre axis, so a value that clears the blocks has
// to be worked out from the layer dimensions, and every route needs its own
// height or they overlap. Picking those by hand means all of them shift as soon
// as a connection is added.
//
// Routes take the default mode, which runs over the top of the stack.
//
// pos: auto places a route clear of the tallest layer and packs routes into the
// fewest lanes that keep them apart: sort by where a route starts, give it the
// lowest lane whose previous occupant has already finished.
//
// The spans below cover all three interval relationships in one figure:
//   l1 -> l8   spans everything
//   l2 -> l4   nested inside it
//   l5 -> l7   nested, and disjoint from l2 -> l4, so it may reuse that lane
//   l3 -> l6   partially overlaps both of the nested pair

#let layer(n) = (type: "conv", widths: (0.3,), height: 2.5, depth: 2.5, name: "l" + str(n), offset: 1.0)

#draw-network(
  range(1, 9).map(layer),
  connections: (
    (from: "l1", to: "l8", type: "skip", pos: auto),
    (from: "l2", to: "l4", type: "skip", pos: auto),
    (from: "l5", to: "l7", type: "skip", pos: auto),
    (from: "l3", to: "l6", type: "skip", pos: auto),
  ),
)

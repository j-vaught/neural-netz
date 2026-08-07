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
// pos: auto places a route clear of the tallest layer and sets its height from
// how far it reaches: a route spanning more blocks sits higher, so a longer
// route always arcs over a shorter one instead of crossing it.
//
// Reaches are ranked rather than used directly. One seven-block route among
// two-block ones would otherwise leave four empty lanes below it.
//
// The spans below cover all three interval relationships in one figure:
//   l1 -> l8   spans everything
//   l2 -> l4   nested inside it
//   l5 -> l7   nested, and disjoint from l2 -> l4, so it may reuse that lane
//   l3 -> l6   partially overlaps both of the nested pair
//
// Reaches here are 2, 2, 3 and 7, so the two reach-2 routes share a height.

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

#v(8mm)

// Equal reach normally means equal height, which would draw two overlapping
// routes of the same reach as a single line. The second goes to the opposite
// side of the axis at the same height instead, so both stay legible and neither
// is pushed further out than its reach warrants. Both routes below reach 3 and
// overlap.
#draw-network(range(1, 8).map(layer), connections: (
  (from: "l1", to: "l4", type: "skip", pos: auto),
  (from: "l3", to: "l6", type: "skip", pos: auto),
))

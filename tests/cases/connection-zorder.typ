#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 2.4 -- connection z-order.
//
// Connections are drawn in a final pass after every layer box, so a route is
// painted over anything it crosses. That is fine while routes stay in open
// space and wrong as soon as one has to pass a layer.
//
// Both figures are identical except for `z` on the single skip, which is routed
// deliberately through layer b's body rather than around it.

#let fig(z) = draw-network((
  (type: "conv", widths: (0.4,), height: 3, depth: 3, label: "a", name: "a"),
  (type: "conv", widths: (0.4,), height: 3, depth: 3, label: "b", name: "b", offset: 1.6),
  (type: "conv", widths: (0.4,), height: 3, depth: 3, label: "c", name: "c", offset: 1.6),
), connections: (
  (from: "a", to: "c", type: "skip", mode: "flat", pos: 0.8, z: z),
))

// front, the default: the route is drawn across layer b.
#fig("front")

#v(7mm)

// behind: the same route passes under it.
#fig("behind")

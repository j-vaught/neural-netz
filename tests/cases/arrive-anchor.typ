#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 3.9 -- named arrival anchors.
//
// touch-layer resolves to exactly three arrival points, one per routing mode. A
// fourth connection into the same layer has to reuse one, and two connections in
// the same mode land on the identical pixel with their arrowheads stacked.
//
// to-anchor names the point instead, and arrive-offset shifts along the edge it
// sits on: horizontally for the top and bottom edges, vertically for the left
// one. Several routes can then fan into one layer, which is what a concat needs.

#let src(n) = (
  type: "conv", widths: (0.3,), height: 2.5, depth: 2.5,
  name: "s" + str(n), label: "s" + str(n), offset: 1.1,
)

// Three routes into one concat, all on the same anchor, separated only by
// arrive-offset. Expect three distinct arrowheads, evenly spaced.
#draw-network(
  (src(1), src(2), src(3), (type: "concat", height: 3.2, depth: 3.2, name: "cat", label: "concat", offset: 2.6)),
  connections: (
    (from: "s1", to: "cat", to-anchor: "nw", arrive-offset: -0.3, pos: auto),
    (from: "s2", to: "cat", to-anchor: "nw", arrive-offset: 0, pos: auto),
    (from: "s3", to: "cat", to-anchor: "nw", arrive-offset: 0.3, pos: auto),
  ),
)

#v(9mm)

// The five named anchors, one route each, so each point is identifiable.
//   nw  top edge, at the west corner
//   n   top edge, centred
//   sw  bottom edge, at the west corner
//   s   bottom edge, centred
//   w   left edge, centred vertically
#draw-network(
  (src(1), src(2), src(3), src(4), src(5),
   (type: "concat", height: 3.2, depth: 3.2, name: "cat", label: "concat", offset: 3.0)),
  connections: (
    (from: "s1", to: "cat", to-anchor: "nw", pos: auto, color: rgb("#73000A"), legend: "nw"),
    (from: "s2", to: "cat", to-anchor: "n", pos: auto, color: rgb("#466A9F"), legend: "n"),
    (from: "s3", to: "cat", to-anchor: "w", pos: auto, color: rgb("#65780B"), legend: "w"),
    (from: "s4", to: "cat", to-anchor: "sw", mode: "flat", pos: auto, color: rgb("#A49137"), legend: "sw"),
    (from: "s5", to: "cat", to-anchor: "s", mode: "flat", pos: auto, color: rgb("#1F414D"), legend: "s"),
  ),
  show-legend: true,
  legend-title: "Anchors",
)

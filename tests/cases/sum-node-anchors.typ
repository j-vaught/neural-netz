#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 4mm)

// A sum node as a connection endpoint.
//
// Every other layer is a prism, and `get-layer-anchors` puts its true east and
// west at the centre of the sheared side face: half the depth-lean above the
// block's own middle. A sum node is a flat circle sitting on the axis with no
// lean, and it was being anchored as though it had one, half a radius up and
// half a radius across from where it was drawn.
//
// Nothing showed until a connection used it as an endpoint, because the anchors
// are only read to place routes and group brackets. Then a route departing the
// node left from a point that was not on the arrow it was supposed to leave, and
// the arrowhead redrawn at that anchor floated above the trunk beside the real
// one, so the route read as joining nothing.
//
// Expected in both rows: one arrowhead per gap, the coloured route leaving from
// the trunk line just behind the head, and the bracket ending at the circle.

#let blk(n, l) = (type: "conv", widths: (0.4,), height: 3, depth: 2, label: l, offset: 1.8, name: n)

// Departing the sum, and arriving at it.
#draw-network((
  (type: "input", height: 3, depth: 2, label: "in", show-connection: true, name: "i"),
  (type: "sum", label: "sum", radius: 0.42, name: "s", offset: 1.6),
  blk("b1", "b1"), blk("b2", "b2"), blk("b3", "b3"),
), groups: (
  (from: "i", to: "s", label: "through the sum"),
), connections: (
  (from: "s", to: "b3", type: "skip", mode: "air", pos: 2.5, color: rgb("#466A9F")),
  (from: "i", to: "s", type: "skip", mode: "flat", pos: 2.5, color: rgb("#CC2E40")),
))

#v(8mm)

// The same, with the sum immediately after a branch rejoin: the node is placed
// with the previous depth offset folded in, which is what the recorded box has
// to be built from rather than worked back from the cursor.
#draw-network((
  (type: "branch", spread: 6, branches: (
    ((type: "input", height: 3, depth: 2, label: "a", show-connection: true),),
    ((type: "input", height: 3, depth: 2, label: "b", show-connection: true),),
  )),
  (type: "sum", label: "sum", radius: 0.42, name: "s", offset: 1.6),
  blk("b1", "b1"), blk("b2", "b2"), blk("b3", "b3"),
), connections: (
  (from: "s", to: "b3", type: "skip", mode: "air", pos: 2.5, color: rgb("#466A9F")),
))

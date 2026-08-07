#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 2.7 -- group brackets.
//
// Backbone, neck and head are the phrases anyone uses out loud to explain one of
// these figures, and there was no way to draw them.
//
// A square bracket rather than a brace, since everything else in the package is
// drawn with flat edges. The span covers the drawn footprint, which leans right
// of the front face by the isometric shear, so a bracket sits under the whole
// block rather than under its front face only.

#let layer(n, h) = (
  type: "conv", widths: (0.4,), height: h, depth: h,
  name: "l" + str(n), label: "l" + str(n), offset: 1.2,
)

// The ordinary case: two groups over two layers each.
#draw-network(
  (layer(1, 3), layer(2, 3), layer(3, 2), layer(4, 2)),
  groups: (
    (from: "l1", to: "l2", label: "encoder"),
    (from: "l3", to: "l4", label: "decoder"),
  ),
)

#v(9mm)

// Edge cases in one figure:
//   l1        a group spanning a single layer
//   l2 - l3   adjacent to the next group, so the two must not run together
//   l4 - l5   ditto
//   l1 - l5   an outer group enclosing all of them, on its own row
#draw-network(
  (layer(1, 3), layer(2, 3), layer(3, 3), layer(4, 2), layer(5, 2)),
  groups: (
    (from: "l1", to: "l1", label: "stem"),
    (from: "l2", to: "l3", label: "middle"),
    (from: "l4", to: "l5", label: "head"),
    (from: "l1", to: "l5", label: "whole network", offset: 2.3),
  ),
)

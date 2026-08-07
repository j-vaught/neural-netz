#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 2.5 -- per-connection stroke styling.
//
// All four skips below have identical geometry: same span, same mode, same pos,
// shifted along the axis. Matching the routing is what isolates styling from
// layout, so any difference you see is the style and nothing else.
//
//   color      paint for the line and its arrowheads
//   dash       any Typst dash pattern
//   thickness  multiplies the palette width, so a figure passing
//              stroke-thickness to draw-network still scales its connections
//
// Arrowheads take the line colour. A red line with black arrowheads reads as a
// bug rather than as a choice.

#let garnet = rgb("#73000A")
#let atlantic = rgb("#466A9F")

#let layer(n) = (type: "conv", widths: (0.3,), height: 2.5, depth: 2.5, name: "l" + str(n), offset: 1.0)

#draw-network(
  range(1, 10).map(layer),
  connections: (
    (from: "l1", to: "l3", type: "skip", mode: "air", pos: 1.2, label: "default"),
    (from: "l3", to: "l5", type: "skip", mode: "air", pos: 1.2, label: "dashed", dash: "dashed"),
    (from: "l5", to: "l7", type: "skip", mode: "air", pos: 1.2, label: "colour", color: garnet),
    (from: "l7", to: "l9", type: "skip", mode: "air", pos: 1.2, label: "thick + dotted",
      color: atlantic, dash: "dotted", thickness: 2),
  ),
)

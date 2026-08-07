#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 2.5 -- per-connection stroke styling.
//
// All four skips below have identical geometry: same span, same mode, same pos,
// shifted along the axis. Matching the routing is what isolates styling from
// layout, so any difference you see is the style and nothing else.
//
// Mode is left at the default, which routes over the top. pos is fixed rather
// than auto here, precisely so the geometry stays identical.
// Automatic lanes are exercised in connection-auto-lane.typ.
//
//   color      paint for the line and its arrowheads
//   dash       any Typst dash pattern
//   thickness  multiplies the palette width, so a figure passing
//              stroke-thickness to draw-network still scales its connections
//   legend     names the style, adding a legend entry drawn as a line sample
//              rather than a colour swatch, since what distinguishes a
//              connection is its stroke and not a fill
//
// Arrowheads take the line colour. A red line with black arrowheads reads as a
// bug rather than as a choice.

#let garnet = rgb("#73000A")
#let atlantic = rgb("#466A9F")

#let layer(n) = (type: "conv", widths: (0.3,), height: 2.5, depth: 2.5, name: "l" + str(n), offset: 1.0)

#draw-network(
  range(1, 10).map(layer),
  connections: (
    (from: "l1", to: "l3", type: "skip", pos: 2.2, label: "default", legend: "plain skip"),
    (from: "l3", to: "l5", type: "skip", pos: 2.2, label: "dashed", dash: "dashed", legend: "auxiliary"),
    (from: "l5", to: "l7", type: "skip", pos: 2.2, label: "colour", color: garnet, legend: "residual add"),
    (from: "l7", to: "l9", type: "skip", pos: 2.2, label: "thick + dotted",
      color: atlantic, dash: "dotted", thickness: 2, legend: "attention route"),
  ),
  show-legend: true,
  legend-title: "Connections",
  main-legend: "forward pass",
)

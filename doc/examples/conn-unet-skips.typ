#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#let enc = (widths: (0.3,))
#draw-network(
  (
    conv(name: "e1", label: "e1", height: 6, depth: 6, ..enc),
    conv(name: "e2", label: "e2", height: 4.5, depth: 4.5, ..enc),
    conv(name: "e3", label: "e3", height: 3, depth: 3, ..enc),
    deconv(name: "d3", label: "d3", height: 4.5, depth: 4.5),
    deconv(name: "d2", label: "d2", height: 6, depth: 6),
  ),
  connections: (
    (from: "e2", to: "d3", touch-layer: true),
    (from: "e1", to: "d2", touch-layer: true),
  ),
)

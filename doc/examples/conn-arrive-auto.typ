#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Three arrivals on one edge, spaced without picking numbers
#draw-network(
  (
    conv(name: "a", label: "a"), conv(name: "b", label: "b"),
    conv(name: "c", label: "c"),
    concat(name: "cat", label: "concat", depth: 6),
  ),
  connections: (
    (from: "a", to: "cat", touch-layer: true),
    (from: "b", to: "cat", touch-layer: true),
    (from: "c", to: "cat", touch-layer: true),
  ),
)

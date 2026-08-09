#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "a", label: "a"), conv(name: "b", label: "b"),
    concat(name: "cat", label: "concat", depth: 6),
  ),
  connections: (
    (from: "a", to: "cat", touch-layer: true, arrive-offset: -0.6),
    (from: "b", to: "cat", touch-layer: true, arrive-offset: 0.6),
  ),
)

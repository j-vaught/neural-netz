#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#let t = (touch-layer: true)
#draw-network(
  (
    conv(name: "a", label: "a"),
    conv(name: "b", label: "b"),
    conv(name: "c", label: "c"),
    concat(name: "cat", label: "concat", depth: 5, height: 5),
  ),
  connections: (
    (from: "a", to: "cat", mode: "air", ..t),
    (from: "b", to: "cat", mode: "flat", ..t),
    (from: "c", to: "cat", mode: "depth", ..t),
  ),
)

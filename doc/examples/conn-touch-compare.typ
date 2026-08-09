#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "a", label: "a"),
    conv(name: "b", label: "b"),
    concat(name: "cat", label: "concat", depth: 5),
  ),
  connections: (
    // on the axis arrow in front of the target
    (from: "a", to: "cat"),
    // on the target block itself
    (from: "b", to: "cat", touch-layer: true),
  ),
)

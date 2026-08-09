#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "a", label: "a"), conv(name: "b", label: "b"),
    concat(name: "cat", label: "concat"),
  ),
  connections: (
    (from: "a", to: "cat"),                     // arrives on the axis arrow
    (from: "b", to: "cat", touch-layer: true),  // arrives on the block itself
  ),
)

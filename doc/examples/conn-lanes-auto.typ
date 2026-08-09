#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Longer routes arc over shorter ones, unasked
#draw-network(
  (
    conv(name: "a"), conv(name: "b"), conv(name: "c"),
    conv(name: "d"), conv(name: "e"),
  ),
  connections: (
    (from: "a", to: "e"),
    (from: "b", to: "d"),
    (from: "c", to: "d"),
  ),
)

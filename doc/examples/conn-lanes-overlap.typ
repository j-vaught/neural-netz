#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Equal reach, overlapping: the second goes below the axis
#draw-network(
  (
    conv(name: "a"), conv(name: "b"),
    conv(name: "c"), conv(name: "d"),
  ),
  connections: (
    (from: "a", to: "c"),
    (from: "b", to: "d"),
  ),
)

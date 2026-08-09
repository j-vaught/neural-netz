#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "a"), conv(name: "b"),
    conv(name: "c"), conv(name: "d"),
  ),
  connections: (
    // the longer route arcs over the shorter
    (from: "a", to: "d"),
    (from: "b", to: "c"),
  ),
)

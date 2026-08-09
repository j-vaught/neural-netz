#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "a"), conv(name: "b"),
    conv(name: "c"), conv(name: "d"),
  ),
  connections: (
    (from: "a", to: "c", color: rgb("#73000A"), thickness: 2),
    (from: "b", to: "d", color: rgb("#466A9F"), dash: "dashed"),
  ),
)

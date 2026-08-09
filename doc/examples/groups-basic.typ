#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "e1"), conv(name: "e2"),
    conv(name: "d1"), conv(name: "d2"),
  ),
  groups: (
    (from: "e1", to: "e2", label: "Encoder"),
    (from: "d1", to: "d2", label: "Decoder"),
  ),
)

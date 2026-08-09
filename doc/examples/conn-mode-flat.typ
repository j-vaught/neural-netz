#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (conv(name: "a"), conv(), conv(name: "c")),
  connections: ((from: "a", to: "c", mode: "flat"),),
)

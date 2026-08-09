#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (conv(name: "a"), conv(name: "b"), conv(name: "c")),
  connections: (
    (from: "a", to: "c", color: rgb("#73000A"),
     legend: "residual add"),
  ),
  show-legend: true,
  main-legend: "forward pass",
)

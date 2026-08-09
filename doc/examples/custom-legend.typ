#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    custom(label: "a", fill: rgb("#466A9F"), legend: "my block"),
    custom(label: "b", fill: rgb("#466A9F")),
    custom(label: "c", fill: rgb("#A49137"), legend: "other block"),
  ),
  show-legend: true,
)

#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (conv(), pool(), convres(), fc()),
  show-legend: true,
)

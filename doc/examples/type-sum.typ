#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(),
  sum(),
  sum(symbol: [$times$], radius: 0.5, fill: rgb("#FFF2E3")),
  conv(),
))

#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(),
  sum(),
  sum(symbol: [$times$]),
  sum(radius: 0.6, fill: rgb("#FFF2E3"), stroke: rgb("#73000A")),
  conv(),
))

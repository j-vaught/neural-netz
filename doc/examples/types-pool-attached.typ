#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// No offset: the pool sits against the block in front
#draw-network((
  conv(label: "conv"),
  pool(),
  conv(label: "conv"),
  pool(),
))

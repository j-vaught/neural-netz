#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(depth: 4),
  conv(depth: 4, offset: 1.4),
  conv(depth: 4, offset: 3.5),
))

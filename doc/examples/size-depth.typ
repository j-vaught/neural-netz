#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "1", depth: 1),
  conv(label: "4", depth: 4),
  conv(label: "8", depth: 8),
))

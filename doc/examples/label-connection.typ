#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "a", connection-label: "stride 2", height: 4, depth: 4),
  conv(label: "b", height: 4, depth: 4, offset: 3),
))

#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "tall",  height: 7, depth: 3, widths: (0.4,)),
  conv(label: "deep",  height: 3, depth: 7, widths: (0.4,)),
  conv(label: "thick", height: 3, depth: 3, widths: (1.6,)),
))

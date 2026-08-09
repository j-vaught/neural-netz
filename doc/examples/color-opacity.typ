#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(opacity: 0.2, height: 4, depth: 4, widths: (0.6,)),
  conv(opacity: 0.6, height: 4, depth: 4, widths: (0.6,)),
  conv(opacity: 1.0, height: 4, depth: 4, widths: (0.6,)),
))

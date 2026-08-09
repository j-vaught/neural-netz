#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(height: 4, depth: 4, widths: (0.3,)),
  conv(height: 4, depth: 4, widths: (0.3,), offset: 1.4),
  conv(height: 4, depth: 4, widths: (0.3,), offset: 3.5),
))

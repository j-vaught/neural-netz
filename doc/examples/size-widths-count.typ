#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "x1", widths: (0.4,)),
  conv(label: "x2", widths: (0.4, 0.4)),
  conv(label: "x3", widths: (0.4, 0.4, 0.4)),
))

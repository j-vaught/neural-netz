#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "one", widths: (0.8,)),
  conv(label: "three", widths: (0.4, 0.4, 0.4)),
  conv(label: "uneven", widths: (0.2, 0.8, 0.2)),
))

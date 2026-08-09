#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "one band",   widths: (0.8,),          height: 4, depth: 4),
  conv(label: "three",      widths: (0.4, 0.4, 0.4), height: 4, depth: 4),
  conv(label: "uneven",     widths: (0.2, 0.8, 0.2), height: 4, depth: 4),
))

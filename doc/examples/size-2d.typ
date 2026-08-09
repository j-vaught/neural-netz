#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "3D", height: 4, depth: 4, widths: (0.4,)),
  fc(label: "2D",  height: 4, depth: 0),
))

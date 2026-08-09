#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: [conv 3x3 \ stride 2]),
  conv(label: [conv 1x1]),
))

#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#let b = (height: 3, depth: 3, widths: (0.3,), offset: 2)
#draw-network((
  conv(label: "horizontal", ..b),
  conv(label: "diagonal", label-orient: "diagonal", ..b),
  conv(label: "vertical", label-orient: "vertical", ..b),
))

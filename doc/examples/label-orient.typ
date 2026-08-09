#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "horizontal", height: 3, depth: 3, widths: (0.3,)),
  conv(label: "diagonal", height: 3, depth: 3, widths: (0.3,), label-orient: "diagonal"),
  conv(label: "vertical", height: 3, depth: 3, widths: (0.3,), label-orient: "vertical"),
))

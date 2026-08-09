#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Not only the input takes one
#draw-network((
  input(image: "default", label: "in"),
  conv(image: "default", label: "features",
       depth: 4, widths: (0.4,), offset: 2),
))

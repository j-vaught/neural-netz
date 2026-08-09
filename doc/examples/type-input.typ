#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  input(image: "default", height: 5, depth: 5),
  conv(label: "conv"),
))

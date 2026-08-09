#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  (type: "conv", label: "a"),
  (type: "pool",),
  (type: "conv", label: "b"),
))

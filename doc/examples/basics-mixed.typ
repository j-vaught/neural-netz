#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// The two forms mix freely
#draw-network((
  conv(label: "ctor"),
  (type: "conv", label: "dict"),
  conv(label: "ctor"),
))

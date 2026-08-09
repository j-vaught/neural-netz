#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Anchor the outer labels by their facing edges
#let b = (height: 3, depth: 3, widths: (0.3,), offset: 0.6)
#draw-network((
  conv(label: "left", label-anchor: "base-east",
       label-dx: -0.2, ..b),
  conv(label: "mid", ..b),
  conv(label: "right", label-anchor: "base-west",
       label-dx: 0.2, ..b),
))

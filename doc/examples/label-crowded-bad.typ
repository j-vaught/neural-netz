#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Long labels, blocks close together
#let b = (height: 3, depth: 3, widths: (0.3,), offset: 0.6)
#draw-network((
  conv(label: "convolution", ..b),
  conv(label: "downsample", ..b),
  conv(label: "projection", ..b),
))

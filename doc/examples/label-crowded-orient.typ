#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Rotating trades scarce horizontal space for free vertical space
#let b = (
  height: 3, depth: 3, widths: (0.3,), offset: 0.6,
  label-orient: "diagonal",
)
#draw-network((
  conv(label: "convolution", ..b),
  conv(label: "downsample", ..b),
  conv(label: "projection", ..b),
))

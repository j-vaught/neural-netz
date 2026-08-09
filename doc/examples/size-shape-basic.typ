#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// (channels, height, width) of the tensor produced
#draw-network((
  conv(shape: (64, 128, 128), label: "64x128"),
  conv(shape: (256, 32, 32), label: "256x32"),
))

#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// one number per band
#draw-network((
  conv(channels: (64,)),
  conv(channels: (128, 256), widths: (0.4, 0.4)),
))

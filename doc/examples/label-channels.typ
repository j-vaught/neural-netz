#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  // one number per band
  conv(channels: (64,)),
  conv(channels: (128, 256), widths: (0.4, 0.4)),
  // one extra: the diagonal axis label
  conv(channels: (512, 32)),
))

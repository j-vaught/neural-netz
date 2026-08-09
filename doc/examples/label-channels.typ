#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(channels: (64,), height: 4, depth: 4),
  conv(channels: (128, 256), height: 4, depth: 4),
  // a third entry becomes the diagonal axis label
  conv(channels: (256, 512, 32), height: 4, depth: 4),
))

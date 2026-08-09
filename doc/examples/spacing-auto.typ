#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// No offsets stated: each gap covers the previous block's lean, plus a strip
#draw-network((
  conv(shape: (64, 128, 128)),
  conv(shape: (128, 64, 64)),
  conv(shape: (256, 32, 32)),
))

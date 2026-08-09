#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "down", height: 6, depth: 6),
  pool(height: 4, depth: 4),
  conv(label: "mid", height: 3.5, depth: 3.5),
  unpool(height: 4, depth: 4, offset: 1.5),
  deconv(label: "up", height: 6, depth: 6),
))

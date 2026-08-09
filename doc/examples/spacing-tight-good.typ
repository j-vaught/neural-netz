#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// The same blocks, spaced automatically
#draw-network((
  conv(height: 7, depth: 7),
  conv(height: 7, depth: 7),
  conv(height: 7, depth: 7),
))

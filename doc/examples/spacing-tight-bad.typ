#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// A fixed offset narrower than the block's own lean
#draw-network((
  conv(height: 7, depth: 7),
  conv(height: 7, depth: 7, offset: 1.2),
  conv(height: 7, depth: 7, offset: 1.2),
))

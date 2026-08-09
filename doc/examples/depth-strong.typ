#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (conv(depth: 5), conv(depth: 5)),
  depth-multiplier: 0.6,
)

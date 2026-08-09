#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (conv(widths: (0.8,)), conv(widths: (0.8,))),
  show-relu: false,
)

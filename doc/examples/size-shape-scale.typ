#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Steeper: same shapes, more separation between them
#draw-network(
  (conv(shape: (64, 128, 128)), conv(shape: (256, 32, 32))),
  shape-scale: (
    spatial: (2.0, -6.0),
    channels: (0.15, 0.0),
  ),
)

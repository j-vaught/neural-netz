#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  input(image: image("../../examples/networks/mnist-img-sample.jpg"),
        height: 5, depth: 5, channels: (1, 28)),
  conv(),
))

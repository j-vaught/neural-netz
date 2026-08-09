#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#let mnist = "../../examples/networks/mnist-img-sample.jpg"
#draw-network((
  input(image: image(mnist), channels: (1, 28)),
  conv(),
))

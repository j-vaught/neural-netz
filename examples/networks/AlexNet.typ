#import "../../src/lib.typ": draw-network // FOR YOUR OWN FILES, IMPORT THE FUNCTION FROM THE NEURAL-NETZ PACKAGE INSTEAD

#set page(width: auto, height: auto, margin: 5mm)

#let layers = (
  (
    type: "input",
    image: "default",
    height: 8,
    depth: 8,
    label: "input",
    channels: (3, 224),
    show-connections: true,
  ),
  (
    type: "conv",
    widths: (0.5,),
    height: 6,
    depth: 6,
    label: "\n    f = 11\nstride = 4",
    channels: (96, 55),
    offset: 2,
    legend: "Convolution+ReLU"
  ),
  (
    type: "pool",
    height: 4,
    depth: 4,
  ),
  (
    type: "conv",
    widths: (1.2,),
    height: 4,
    depth: 4,
    label: "f = 5",
    channels: (256, 27),
  ),
  (
    type: "pool",
    height: 2,
    depth: 2,
  ),
  (
    type: "conv",
    widths: (1.6,),
    height: 2,
    depth: 2,
    label: "f = 3",
    channels: (384, 13),
  ),
  (
    type: "conv",
    widths: (1.6,),
    height: 2,
    depth: 2,
    label: "f = 3",
    channels: (384,  13),
  ),
  (
    type: "conv",
    widths: (1.2,),
    height: 2,
    depth: 2,
    label: "f = 3",
    channels: (256, 13),
  ),
  (
    type: "fc",
    label: "",
    channels: (4096,),
    height: 5,
    depth: 0.3,
    offset: 0.8,
    legend: "Fully Connected+ReLU"
  ),
  (
    type: "fc",
    label: "",
    channels: (4096,),
    height: 5,
    depth: 0.3,
    offset: 0.5,
  ),
  (
    type: "fc",
    label: "",
    channels: (1000,),
    height: 4,
    depth: 0.3,
    offset: 0.5,
  ),
  (
    type: "softmax",
    label: "softmax",
    height: 4,
    depth: 0.3,
    offset: 0.9,
  ),
)

#draw-network(
  layers,
  show-legend: true,
  show-relu: true,
)
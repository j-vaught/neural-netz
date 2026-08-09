#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// A whole small classifier, using nothing but types and labels
#draw-network(
  (
    input(image: "default", label: "image", channels: (3, 224)),
    conv(label: "conv1", channels: (64,), offset: 1.4),
    pool(),
    conv(label: "conv2", channels: (128,)),
    pool(),
    gap(label: "gap"),
    fc(label: "fc", channels: (1000,), depth: 0),
    softmax(label: "softmax"),
  ),
  show-legend: true,
)

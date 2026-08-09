#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    input(name: "in", image: "default", shape: (3, 224, 224),
          channels: (3, 224)),
    conv(name: "c1", label: "conv1", shape: (64, 112, 112),
         channels: (64, 112)),
    pool(),
    conv(name: "c2", label: "conv2", shape: (128, 56, 56),
         channels: (128, 56), widths: (0.4, 0.4)),
    pool(),
    conv(name: "c3", label: "conv3", shape: (256, 28, 28),
         channels: (256, 28), widths: (0.4, 0.4)),
    gap(name: "g", label: "gap"),
    fc(name: "f", label: "fc", channels: (1000,), depth: 0),
    softmax(name: "s", label: "softmax"),
  ),
  groups: (
    (from: "c1", to: "c3", label: "Feature extractor"),
    (from: "g", to: "s", label: "Classifier"),
  ),
  show-legend: true,
  show-relu: true,
)

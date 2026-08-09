#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(label: "features"),
    fc(label: "fc", channels: (4096,), depth: 0),
    softmax(label: "softmax"),
    output(label: "output", offset: 2),
  ),
  show-legend: true,
)

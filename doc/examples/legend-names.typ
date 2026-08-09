#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(legend: "3x3 convolution"),
    pool(legend: "max pool"),
    fc(legend: "linear"),
  ),
  show-legend: true,
  legend-title: "Operations",
)

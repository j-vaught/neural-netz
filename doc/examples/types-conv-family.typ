#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(label: "conv", widths: (0.5,)),
    convres(label: "convres", widths: (0.5,)),
    custom(label: "custom", width: 0.5),
  ),
  show-legend: true,
)

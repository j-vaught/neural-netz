#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "in", label: "in", widths: (0.3,)),
    convres(name: "c1", label: "3x3", widths: (0.5,)),
    convres(name: "c2", label: "3x3", widths: (0.5,)),
    sum(name: "add"),
    conv(name: "out", label: "out", widths: (0.3,)),
  ),
  connections: (
    (from: "in", to: "add", color: rgb("#466A9F"),
     legend: "identity shortcut"),
  ),
  groups: ((from: "c1", to: "add", label: "residual block"),),
  show-legend: true,
)

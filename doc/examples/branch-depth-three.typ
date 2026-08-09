#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "in"),
  branch(
    spread: 3.5, spread-mode: "depth", rejoin-lead: 3,
    branches: (
      (conv(label: "P3"),),
      (conv(label: "P4"),),
      (conv(label: "P5"),),
    ),
  ),
  output(label: "detect"),
))

#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "in", widths: (0.3,)),
  branch(spread: 3.4, lead: 1.6, branches: (
    (conv(label: "1x1", widths: (0.2,)),),
    (conv(label: "3x3", widths: (0.4,)),),
    (conv(label: "5x5", widths: (0.6,)),),
  )),
  concat(label: "concat"),
))

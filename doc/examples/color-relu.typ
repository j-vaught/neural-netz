#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(label: "no band", height: 4, depth: 4, widths: (0.8,), show-relu: false),
    conv(label: "default band", height: 4, depth: 4, widths: (0.8,)),
    conv(label: "own band", height: 4, depth: 4, widths: (0.8,),
         fill: rgb("#466A9F"), bandfill: rgb("#CED318")),
  ),
  show-relu: true,
)

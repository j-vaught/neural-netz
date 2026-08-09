#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(label: "derived band", widths: (0.8,),
         fill: rgb("#466A9F")),
    conv(label: "stated band", widths: (0.8,),
         fill: rgb("#466A9F"), bandfill: rgb("#CED318")),
  ),
  show-relu: true,
)

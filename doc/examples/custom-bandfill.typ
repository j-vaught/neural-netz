#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  custom(
    label: "with a band",
    widths: (0.3, 0.5),
    fill: rgb("#65780B"),
    bandfill: rgb("#CED318"),
    show-relu: true,
  ),
))

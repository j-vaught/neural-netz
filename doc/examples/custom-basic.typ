#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  custom(label: "mine", fill: rgb("#466A9F")),
  custom(
    label: "also mine",
    widths: (0.2, 0.4, 0.2),
    fill: rgb("#1F414D"),
  ),
))

#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  custom(label: "plain"),
  custom(label: "coloured", fill: rgb("#466A9F")),
  custom(label: "thin", width: 0.15, fill: rgb("#1F414D")),
))

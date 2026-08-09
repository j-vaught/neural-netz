#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  custom(image: [hello], label: "text"),
  custom(image: [#rect(width: 60%, height: 60%, fill: red)],
         label: "any content"),
))

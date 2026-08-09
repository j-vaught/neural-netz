#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    custom(
      label: "banded",
      widths: (0.3, 0.5, 0.3),
      fill: rgb("#65780B"),
      bandfill: rgb("#CED318"),
      show-relu: true,
    ),
  ),
)

#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Twelve identical blocks, written once
#let block(i) = (
  custom(name: "a" + str(i), label: if i == 1 { "attn" },
         fill: rgb("#466A9F"), width: 0.25, height: 3.5, depth: 3.5,
         legend: "Attention"),
  custom(name: "m" + str(i), label: if i == 1 { "mlp" },
         fill: rgb("#A49137"), width: 0.4, height: 3.5, depth: 3.5,
         legend: "MLP"),
)

#draw-network(
  (custom(name: "in", label: "tokens", width: 0.2,
          height: 3.5, depth: 3.5),)
    + range(1, 7).map(block).flatten(),
  groups: ((from: "a1", to: "m6", label: "6 encoder blocks"),),
  show-legend: true,
)

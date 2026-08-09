#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Your own block type is a function returning a layer
#let attention(..args) = custom(
  fill: rgb("#466A9F"), width: 0.35, height: 4, depth: 4,
  legend: "Attention", ..args,
)
#let mlp(..args) = custom(
  fill: rgb("#A49137"), width: 0.5, height: 4, depth: 4,
  legend: "MLP", ..args,
)

#draw-network(
  (attention(label: "attn"), mlp(label: "mlp"), attention(label: "attn")),
  show-legend: true,
)

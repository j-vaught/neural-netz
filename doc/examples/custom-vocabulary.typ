#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Your own block type is a function returning a layer
#let attention(..a) = custom(
  fill: rgb("#466A9F"), width: 0.35, legend: "Attention", ..a,
)
#let mlp(..a) = custom(
  fill: rgb("#A49137"), width: 0.55, legend: "MLP", ..a,
)

#draw-network(
  (attention(label: "attn"), mlp(label: "mlp"),
   attention(label: "attn"), mlp(label: "mlp")),
  show-legend: true,
)

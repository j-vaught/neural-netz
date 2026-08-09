#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#let attn(..a) = custom(fill: rgb("#466A9F"), width: 0.3,
  height: 4, depth: 4, legend: "Attention", ..a)
#let mlp(..a) = custom(fill: rgb("#A49137"), width: 0.45,
  height: 4, depth: 4, legend: "MLP", ..a)

#draw-network(
  (
    custom(name: "in", label: "tokens", width: 0.2, height: 4, depth: 4),
    attn(name: "a", label: "attn"),
    sum(name: "s1"),
    mlp(name: "m", label: "mlp"),
    sum(name: "s2"),
  ),
  connections: (
    (from: "in", to: "s1", legend: "residual"),
    (from: "s1", to: "s2"),
  ),
  groups: ((from: "a", to: "s2", label: "encoder block"),),
  show-legend: true,
)

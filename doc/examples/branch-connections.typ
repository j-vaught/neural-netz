#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Named layers inside a branch are ordinary targets
#draw-network(
  (
    conv(name: "in", label: "in"),
    branch(spread: 5, branches: (
      (conv(name: "a", label: "a"),),
      (conv(name: "b", label: "b"),),
    )),
    concat(name: "cat", label: "concat"),
  ),
  connections: (
    (from: "in", to: "cat", mode: "flat",
     color: rgb("#73000A"), legend: "bypass"),
  ),
  groups: ((from: "a", to: "b", label: "parallel paths"),),
  show-legend: true,
)

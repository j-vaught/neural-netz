#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "in"),
  branch(spread: 9, lead: 3, branches: (
    (conv(label: "a"),),
    (conv(label: "b"),),
  )),
  concat(label: "concat"),
))

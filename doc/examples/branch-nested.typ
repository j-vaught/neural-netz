#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "in"),
  branch(spread: 7, branches: (
    (
      branch(spread: 2.6, lead: 1.2, branches: (
        (conv(label: "a1"),),
        (conv(label: "a2"),),
      )),
    ),
    (conv(label: "b"),),
  )),
  conv(label: "out"),
))

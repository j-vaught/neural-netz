#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "trunk"),
  branch(spread: 5, open: "end", branches: (
    (conv(label: "task a"), output(label: "out a")),
    (conv(label: "task b"), output(label: "out b")),
  )),
))

#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// The rejoin waits for the longest branch
#draw-network((
  conv(label: "in"),
  branch(spread: 5, branches: (
    (conv(label: "a1"), conv(label: "a2"), conv(label: "a3")),
    (conv(label: "b1"),),
  )),
  concat(label: "concat"),
))

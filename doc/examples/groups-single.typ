#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// from and to may be the same layer
#draw-network(
  (conv(name: "a"), conv(name: "b"), conv(name: "c")),
  groups: ((from: "b", to: "b", label: "just this one"),),
)

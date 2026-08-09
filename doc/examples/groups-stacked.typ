#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (conv(name: "a"), conv(name: "b"), conv(name: "c")),
  groups: (
    (from: "a", to: "b", label: "stage 1"),
    (from: "c", to: "c", label: "stage 2"),
    (from: "a", to: "c", label: "whole network",
     offset: 2.1, color: rgb("#73000A")),
  ),
)

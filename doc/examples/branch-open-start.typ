#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Nothing before it: a two-input network
#draw-network((
  branch(spread: 5, branches: (
    (input(label: "rgb"), conv(label: "a")),
    (input(label: "ir"), conv(label: "b")),
  )),
  concat(label: "fuse"),
))

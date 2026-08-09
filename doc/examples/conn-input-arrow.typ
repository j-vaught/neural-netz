#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// input defaults to no outgoing arrow; turn it on
#draw-network((
  input(image: "default", show-connection: true),
  conv(label: "conv", offset: 1.5),
))

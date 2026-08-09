#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "a", connection-label: "stride 2"),
  conv(label: "b", offset: 3),
))

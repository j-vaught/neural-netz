#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  // no arrow after this one
  conv(label: "a", show-connection: false),
  conv(label: "b"),
  conv(label: "c"),
))

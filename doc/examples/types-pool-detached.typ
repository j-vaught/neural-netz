#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// An offset detaches it and draws an arrow
#draw-network((
  conv(label: "conv"),
  pool(offset: 1.5),
  conv(label: "conv"),
))

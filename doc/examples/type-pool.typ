#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "conv"),
  pool(),                 // attaches to the block before it
  conv(label: "conv", offset: 2),
  pool(offset: 1.5),      // an offset detaches it
))

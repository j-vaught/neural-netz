#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Reads as though the pool repeats too
#draw-network((
  conv(label: "conv x3", repeat: 3),
  pool(),
))

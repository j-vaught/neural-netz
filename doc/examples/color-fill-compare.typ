#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "default"),
  conv(label: "garnet", fill: rgb("#73000A")),
  conv(label: "atlantic", fill: rgb("#466A9F")),
  conv(label: "horseshoe", fill: rgb("#65780B")),
))

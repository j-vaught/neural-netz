#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "0.2", opacity: 0.2),
  conv(label: "0.5", opacity: 0.5),
  conv(label: "0.8", opacity: 0.8),
  conv(label: "1.0", opacity: 1.0),
))

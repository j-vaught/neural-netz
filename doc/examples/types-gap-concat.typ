#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "features", height: 5, depth: 5),
  gap(label: "gap"),
  concat(label: "concat"),
  fc(label: "fc", channels: (512,)),
))

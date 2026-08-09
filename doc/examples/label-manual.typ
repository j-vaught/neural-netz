#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "lifted", height: 3, depth: 3, widths: (0.3,), label-dy: -0.6),
  conv(label: "east", height: 3, depth: 3, widths: (0.3,),
       label-anchor: "base-east", label-dx: -0.2),
  conv(label: "30 degrees", height: 3, depth: 3, widths: (0.3,),
       label-angle: 30deg, label-anchor: "base-west"),
))

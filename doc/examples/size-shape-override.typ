#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "derived", shape: (256, 40, 40)),
  conv(
    label: "height forced",
    shape: (256, 40, 40),
    height: 7,
  ),
))

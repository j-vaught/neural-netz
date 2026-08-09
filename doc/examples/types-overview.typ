#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  conv(label: "conv"),
  convres(label: "convres"),
  deconv(label: "deconv"),
  concat(label: "concat"),
  gap(label: "gap"),
  fc(label: "fc"),
  sum(),
  softmax(label: "softmax"),
  output(label: "output", offset: 2),
))

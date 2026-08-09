#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network((
  branch(spread: 6, branches: (
    (
      input(label: "RGB", image: "default"),
      conv(name: "r1", label: "conv", shape: (32, 160, 160)),
      conv(name: "r2", label: "conv", shape: (64, 80, 80)),
    ),
    (
      input(label: "IR"),
      conv(name: "i1", label: "conv", shape: (32, 160, 160)),
      conv(name: "i2", label: "conv", shape: (64, 80, 80)),
    ),
  )),
  concat(label: "concat", depth: 5),
  conv(label: "fused", shape: (128, 80, 80)),
))

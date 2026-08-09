#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "s1", label: "P1", shape: (32, 160, 160)),
    conv(name: "s2", label: "P2", shape: (64, 80, 80)),
    convres(name: "s3", label: "P3", shape: (128, 40, 40), repeat: 2),
    conv(name: "n1", label: "neck", shape: (128, 40, 40)),
    conv(name: "h1", label: "head", shape: (64, 40, 40)),
  ),
  groups: (
    (from: "s1", to: "s3", label: "Backbone"),
    (from: "n1", to: "n1", label: "Neck"),
    (from: "h1", to: "h1", label: "Head"),
  ),
)

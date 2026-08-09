#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#let e(n, s) = conv(name: n, label: n, shape: s, channels: (s.at(0), s.at(1)))
#let d(n, s) = deconv(name: n, label: n, shape: s)

#draw-network(
  (
    e("e1", (32, 128, 128)),
    e("e2", (64, 64, 64)),
    e("e3", (128, 32, 32)),
    d("d3", (64, 64, 64)),
    d("d2", (32, 128, 128)),
    conv(name: "out", label: "out", shape: (1, 128, 128)),
  ),
  connections: (
    (from: "e2", to: "d3", touch-layer: true,
     color: rgb("#466A9F"), legend: "skip"),
    (from: "e1", to: "d2", touch-layer: true,
     color: rgb("#466A9F")),
  ),
  groups: (
    (from: "e1", to: "e3", label: "Encoder"),
    (from: "d3", to: "out", label: "Decoder"),
  ),
  show-legend: true,
)

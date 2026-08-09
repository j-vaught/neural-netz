#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "a", label: "a", height: 4, depth: 4, widths: (0.3,)),
    conv(name: "b", label: "b", height: 4, depth: 4, widths: (0.3,)),
    conv(name: "c", label: "c", height: 4, depth: 4, widths: (0.3,)),
    conv(name: "d", label: "d", height: 4, depth: 4, widths: (0.3,)),
    conv(name: "e", label: "e", height: 4, depth: 4, widths: (0.3,)),
  ),
  connections: (
    (from: "a", to: "c", mode: "air", label: "air"),
    (from: "b", to: "d", mode: "flat", label: "flat"),
    (from: "c", to: "e", mode: "depth", label: "depth"),
  ),
)

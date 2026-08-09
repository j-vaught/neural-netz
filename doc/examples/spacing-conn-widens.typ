#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// The gap before "c" widens on its own to let the route down
#draw-network(
  (
    conv(name: "a", label: "a", depth: 6),
    conv(name: "b", label: "b", depth: 6),
    conv(name: "c", label: "c", depth: 6),
  ),
  connections: ((from: "a", to: "c"),),
)

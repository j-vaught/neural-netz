#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "a", label: "a"),
    conv(name: "b", label: "b"),
    conv(name: "c", label: "c"),
  ),
  // names are how connections and groups find a layer
  connections: ((from: "a", to: "c"),),
  groups: ((from: "a", to: "b", label: "pair"),),
)

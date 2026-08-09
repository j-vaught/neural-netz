#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "p3", label: "P3", shape: (128, 40, 40)),
    conv(name: "p4", label: "P4", shape: (256, 20, 20)),
    conv(name: "p5", label: "P5", shape: (512, 10, 10)),
    branch(spread: 4, spread-mode: "depth", rejoin-lead: 3.2,
      open: "end", branches: (
        (conv(name: "h3", label: "head P3", shape: (64, 40, 40)),),
        (conv(name: "h4", label: "head P4", shape: (64, 20, 20)),),
        (conv(name: "h5", label: "head P5", shape: (64, 10, 10)),),
      )),
  ),
  groups: ((from: "p3", to: "p5", label: "Backbone"),),
)

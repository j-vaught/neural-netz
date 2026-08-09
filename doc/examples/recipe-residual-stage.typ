#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
#draw-network(
  (
    conv(name: "in", label: "in", shape: (64, 56, 56)),
    convres(name: "b1", label: "block", shape: (64, 56, 56),
            widths: (0.3, 0.3), repeat: 2),
    sum(name: "a1"),
    convres(name: "b2", label: "block", shape: (128, 28, 28),
            widths: (0.3, 0.3), repeat: 2),
    sum(name: "a2"),
    conv(name: "out", label: "out", shape: (128, 28, 28)),
  ),
  connections: (
    (from: "in", to: "a1", color: rgb("#466A9F"),
     legend: "identity"),
    (from: "a1", to: "a2", color: rgb("#73000A"), dash: "dashed",
     legend: "projected"),
  ),
  groups: (
    (from: "b1", to: "a1", label: "stage 1"),
    (from: "b2", to: "a2", label: "stage 2"),
  ),
  show-legend: true,
)

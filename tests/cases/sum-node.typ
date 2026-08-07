#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 4mm)

// Sum node appearance -- the smallest figure that shows it, so nothing else can
// influence how it reads.
//
// The sum node is an operator rather than a data block, so it renders flat with
// an explicit outline instead of the gradient-shaded fill used by every other
// layer type. Default is a white disc with a black ring and symbol.
//
// Both `fill` and `stroke` are per-layer overrides; the second row of this test
// is in tests/cases/sum-node-custom.typ.

#draw-network((
  (type: "input", label: "input", height: 3, depth: 3, show-connection: true),
  (type: "sum", label: "add", offset: 1.2),
  (type: "output", label: "output", height: 3, offset: 1.2),
),
show-legend: true,
)

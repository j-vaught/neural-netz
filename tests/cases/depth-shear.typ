#import "../../src/lib.typ": draw-network, depth-shear, min-clear-offset

#set page(width: auto, height: auto, margin: 5mm)

// Tier 1.3 -- depth-shear and min-clear-offset.
//
// Layers are drawn in isometric projection, so a layer's far face leans right
// by depth * depth-multiplier. The visual gap between two adjacent layers is
// therefore smaller than the offset between them, and a connection routed into
// what looks like empty space can cross the previous layer's top face.
//
// Both figures below are identical except for the offset before the last layer.

// Compared with a tolerance, not for equality: the default multiplier of 0.3
// has no exact binary representation, so depth-shear(4.5) is 1.3499999999999999
// rather than 1.35. Rounding inside the library would be worse than living with
// this, since the value feeds coordinates rather than being shown to anyone.
#let approx(a, b) = calc.abs(a - b) < 1e-9

#assert(approx(depth-shear(4.5), 1.35), message: "depth-shear(4.5) should be 1.35")
#assert(approx(depth-shear(6), 1.8), message: "depth-shear(6) should be 1.8")
#assert(approx(depth-shear(6, depth-multiplier: 0.5), 3.0), message: "multiplier must be honoured")
#assert(approx(min-clear-offset(6), 3.6), message: "min-clear-offset is twice the shear")

#let fig(off) = draw-network((
  (type: "conv", widths: (0.3,), height: 4, depth: 6, label: "source", name: "src"),
  (type: "conv", widths: (0.3,), height: 4, depth: 6, label: "a", offset: 3, name: "a"),
  (type: "conv", widths: (0.3,), height: 4, depth: 6, label: "b", offset: off, name: "b"),
), connections: (
  (from: "src", to: "b", type: "skip", mode: "air", pos: 2),
))

// offset equal to the shear: the descent lands inside layer a's sheared top
// face and is drawn across it.
#fig(depth-shear(6))

#v(8mm)

// offset at the computed minimum: the descent clears the shear.
#fig(min-clear-offset(6))

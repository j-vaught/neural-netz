#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 1.1 -- a custom layer must show an activation band only when it has one
// to show. All three layers below are identical except for how they relate to
// the band, and the network-level show-relu is on for all of them.
//
// Expected:
//   1. no bandfill declared, inherits show-relu   -> flat, no band
//   2. bandfill declared                          -> banded in #FFE66D
//   3. no bandfill but explicit show-relu: true   -> banded in the palette default
//
// Layer 3 is the case that keeps the fix from being a blunt "ignore show-relu":
// an explicit per-layer opt-in must still work.

#draw-network((
  (
    type: "custom",
    widths: (0.3, 0.3), height: 4, depth: 4,
    fill: rgb("#4ECDC4"), opacity: 0.9,
    label: "inherited",
  ),(
    type: "custom",
    widths: (0.3, 0.3), height: 4, depth: 4,
    fill: rgb("#4ECDC4"), opacity: 0.9,
    bandfill: rgb("#FFE66D"),
    label: "bandfill",
    offset: 1.5,
  ),(
    type: "custom",
    widths: (0.3, 0.3), height: 4, depth: 4,
    fill: rgb("#4ECDC4"), opacity: 0.9,
    show-relu: true,
    label: "explicit",
    offset: 1.5,
  ),
),
show-relu: true,
)

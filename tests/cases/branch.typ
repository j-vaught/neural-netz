#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 4.13 -- parallel branches.
//
// draw-network advances one cursor along one axis, so anything genuinely
// parallel had to be collapsed into a single block with arrows pointed at it.
// A branch is a layer list of its own, walked at its own height and rejoined
// afterwards. Walking one is the same operation as walking the trunk, only
// starting somewhere else.
//
// The call is recursive, so a branch may contain branches.

#let c(lbl) = (type: "conv", widths: (0.4,), height: 2.4, depth: 2.4, label: lbl, offset: 1.3)
#let inp = (type: "input", height: 3, depth: 3, label: "in", show-connection: true)
#let out = (type: "concat", height: 3, depth: 3, label: "concat", offset: 1.3)

// The smallest case: two branches of one layer each.
#draw-network((inp, (type: "branch", spread: 6, branches: ((c("a"),), (c("b"),))), out))

#v(9mm)

// Unequal lengths. The rejoin waits for the longest branch rather than cutting
// the others short, so the short branch's arrow runs on to meet it.
#draw-network((
  inp,
  (type: "branch", spread: 6, branches: (
    (c("a1"), c("a2"), c("a3")),
    (c("b1"),),
  )),
  out,
))

#v(9mm)

// Three branches, centred on the trunk.
#draw-network((
  inp,
  (type: "branch", spread: 9, branches: ((c("a"),), (c("b"),), (c("c"),))),
  out,
))

#v(9mm)

// A branch containing a branch.
#draw-network((
  inp,
  (type: "branch", spread: 10, branches: (
    (
      c("a1"),
      (type: "branch", spread: 4, branches: ((c("a2"),), (c("a3"),))),
    ),
    (c("b1"),),
  )),
  out,
))

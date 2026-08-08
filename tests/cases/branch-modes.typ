#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Branch spread modes.
//
// A branch lays its sub-runs out in one of two ways.
//
//   vertical (default)  branches stack straight above and below the trunk, and
//                       the fan-out and rejoin are right-angled: out, across,
//                       in. Reads as alternatives side by side.
//
//   depth               branches stack along the projection's own 45-degree
//                       axis, away and near, and the fan-out and rejoin are two
//                       parallel spines with horizontal teeth: a parallelogram.
//                       Reads as parallel copies sitting behind one another.
//
// Both are centred on the trunk. An odd count puts one branch on the trunk line
// itself; an even count leaves the trunk line empty, so no block sits directly
// on the main path.

#let blk(lbl, h: 2.4, d: 1.4) = (
  type: "conv", widths: (0.4,), height: h, depth: d, label: lbl, offset: 1.3,
)
#let inp = (type: "input", height: 3, depth: 3, label: "in", show-connection: true)
#let out = (type: "concat", height: 3, depth: 3, label: "out", offset: 1.6)

// ---- vertical, two branches: one above, one below, trunk line empty ----
#draw-network((
  inp,
  (type: "branch", spread: 6, branches: ((blk("a"),), (blk("b"),))),
  out,
))

#v(8mm)

// ---- vertical, three branches: middle sits on the trunk line ----
#draw-network((
  inp,
  (type: "branch", spread: 9, branches: ((blk("a"),), (blk("b"),), (blk("c"),))),
  out,
))

#v(8mm)

// ---- depth, two branches: one away, one near, trunk line empty ----
#draw-network((
  inp,
  (type: "branch", spread: 5, spread-mode: "depth", branches: ((blk("a"),), (blk("b"),))),
  out,
))

#v(8mm)

// ---- depth, three branches: middle on the trunk line, spines split both ways ----
#draw-network((
  inp,
  (type: "branch", spread: 7, spread-mode: "depth", branches: ((blk("a"),), (blk("b"),), (blk("c"),))),
  out,
))

#v(8mm)

// ---- depth, four branches: two away, two near ----
#draw-network((
  inp,
  (type: "branch", spread: 10, spread-mode: "depth",
    branches: ((blk("a"),), (blk("b"),), (blk("c"),), (blk("d"),))),
  out,
))

#v(8mm)

// ---- mixed sizes: the teeth land on each block's own arrow anchor, so blocks
// of different heights and depths join correctly rather than sharing one row
// geometry. The rejoin waits for the widest block's sheared edge. ----
#draw-network((
  inp,
  (type: "branch", spread: 8, spread-mode: "depth", branches: (
    (blk("tall", h: 4.2, d: 1.0),),
    (blk("wide", h: 1.6, d: 3.2),),
    (blk("small", h: 1.2, d: 0.8),),
  )),
  out,
))

#v(8mm)

// ---- unequal lengths, depth mode: the rejoin spine waits for the longest ----
#draw-network((
  inp,
  (type: "branch", spread: 5, spread-mode: "depth", branches: (
    (blk("a1"), blk("a2"), blk("a3")),
    (blk("b1"),),
  )),
  out,
))

#v(8mm)

// ---- open ends: a branch need not close both sides into the trunk ----
//
// A branch with nothing before it is open at the start by definition: the
// branches simply begin, which is how a multi-input network starts. open: "end"
// leaves the other side loose instead, so one trunk fans out into independent
// outputs and nothing merges.
#draw-network((
  inp,
  blk("shared"),
  (type: "branch", spread: 6, open: "end", branches: (
    (blk("task a"), (type: "output", label: "out a", height: 2, depth: 0.3, offset: 1.2)),
    (blk("task b"), (type: "output", label: "out b", height: 2, depth: 0.3, offset: 1.2)),
  )),
))

#v(8mm)

// Both at once: two inputs converge, one trunk, two outputs.
#draw-network((
  (type: "branch", spread: 6, branches: (
    ((type: "input", height: 2.6, depth: 2.6, label: "sensor a", show-connection: true),),
    ((type: "input", height: 2.6, depth: 2.6, label: "sensor b", show-connection: true),),
  )),
  (type: "concat", height: 2.8, depth: 2.8, label: "fuse", offset: 1.6),
  blk("shared"),
  (type: "branch", spread: 6, open: "end", branches: (
    (blk("boxes"),),
    (blk("classes"),),
  )),
))

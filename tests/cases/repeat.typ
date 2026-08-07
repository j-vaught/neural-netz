#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 5mm)

// Tier 2.8 -- repeat: N.
//
// repeat: N means N identical copies of the block in series, each feeding the
// next. It describes one layer entry, not a run of them: (conv, pool) repeated
// as a unit is a different thing and is not expressible here.
//
// Depth-scaled models fake block repetition by stuffing extra entries into
// `widths`. That is a visual coincidence rather than semantics: the package has
// no idea the block is repeated, so it cannot label the repeat or bracket it,
// and the figure claims a wider block rather than a repeated one.
//
// Both rows below are the same architecture. The first fakes it, the second
// declares it. The comparison is the design decision.

// Faked: three entries in widths. Reads as one wide block.
#draw-network((
  (type: "conv", widths: (0.4,), height: 3, depth: 3, label: "conv"),
  (type: "convres", widths: (0.4, 0.4, 0.4), height: 3, depth: 3, label: "bottleneck", offset: 1.4),
  (type: "conv", widths: (0.4,), height: 3, depth: 3, label: "conv", offset: 1.4),
))

#v(9mm)

// Declared: one block, repeated three times.
#draw-network((
  (type: "conv", widths: (0.4,), height: 3, depth: 3, label: "conv"),
  (type: "convres", widths: (0.4,), height: 3, depth: 3, label: "bottleneck", repeat: 3, offset: 1.4),
  (type: "conv", widths: (0.4,), height: 3, depth: 3, label: "conv", offset: 1.4),
))

#v(9mm)

// Counts and layer types, to check the marker and the stack stay legible.
//   repeat: 2 is the smallest that draws anything
//   repeat: 6 is deep enough to test that the ghosts do not swamp the block
//   repeat works on any block type, not only the ones taking `widths`
#draw-network((
  (type: "conv", widths: (0.4,), height: 3, depth: 3, label: "x2", repeat: 2),
  (type: "convres", widths: (0.4,), height: 3, depth: 3, label: "x6", repeat: 6, offset: 2.2),
  (type: "fc", channels: (10,), height: 3, depth: 0.3, label: "fc x4", repeat: 4, offset: 2.4),
))

#v(9mm)

// pool and unpool attach to the block before them rather than being blocks in
// their own right, so repeat is ignored on them.
//
// That makes "three convs then a pool" awkward to say directly: bracketing a
// repeated conv that has a pool attached reads as though the pool repeats too.
// Split it instead. Two plain convs carry the repeat, and the third is drawn on
// its own with the pool attached to it. The bracket then sits over a block with
// nothing attached, so what it covers is unambiguous.
#draw-network((
  (type: "conv", widths: (0.4,), height: 3, depth: 3, label: "conv x2", repeat: 2),
  (type: "conv", widths: (0.4,), height: 3, depth: 3, label: "conv + pool", offset: 2.0),
  (type: "pool", height: 2.4, depth: 2.4),
  (type: "conv", widths: (0.4,), height: 2.4, depth: 2.4, label: "conv", offset: 2.2),
))

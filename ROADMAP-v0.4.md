# neural-netz v0.4 Roadmap

Author: J.C. Vaught

Fork point: `fix/plotting-corners-and-arrows` @ `cb6334b` (corner-spike and arrowhead-transparency
fix already applied on top of `v0.3.0`).

This document is the working plan for v0.4. Items are ordered easiest to hardest, with
dependencies resolved so that a prerequisite always appears before anything that needs it.

## Governing rule

Every new feature is an **opt-in keyword whose default reproduces v0.3 behavior exactly**.
A clean golden-image diff across all 15 bundled examples is therefore the operational
definition of backward compatibility. When a diff is intentional, inspect it, then
re-baseline that single file deliberately rather than re-baselining wholesale.

Pin the Typst version used for baselines. Renderer changes across Typst releases will
otherwise produce false positives. Baselines in this repo were generated with Typst 0.14.2
and CeTZ 0.4.2.

---

## Step 0. Regression harness

Comes before any code change, since everything else is graded against it.

Golden images live in `tests/golden/`, generated from the fork point. Regenerate with
`tests/bless.sh`. Check the working tree against them with `python3 tests/regress.py`,
which recompiles every example into `tests/current/` and pixel-diffs it against its golden.

The examples import `../../src/lib.typ` by relative path rather than from the package
registry, so they track the working tree automatically. No test-specific wiring is needed.

A second, weaker check worth running by eye: the `v0.3.0` tag renders differ from the fork
point only in corner geometry and arrowhead alpha. Those diffs are already accepted.

---

## Tier 1. Trivial, no dependencies

### 1. Fix the `custom` layer bandfill default

`custom` layers inherit network-level `show-relu: true` and paint a grey band even when no
`bandfill` was supplied, which reads as a rendering glitch. Make the band conditional on
`bandfill != none` rather than on `show-relu` alone.

*Test:* two `custom` layers side by side, one with `bandfill`, one without, network-level
`show-relu: true`. Expect exactly one banded block.

### 2. Label offsets: `label-dx`, `label-dy`, `label-anchor`

Additive plumbing into the existing `content()` call for each layer label. Defaults of
`0, 0, "north"` leave every v0.3 render byte-identical. Labels are currently placed at a
fixed spot under each block with no awareness of neighbours, so tight offsets silently
collide with the diagonal channel text.

*Test:* three identical layers at a deliberately tight `offset: 0.4` so their labels
collide. Add `label-dy: -0.5` to the middle one and confirm only that one moves.

### 3. Export a shear helper

`get-depth-offsets` (`src/lib.typ:108`) is private, so the fact that visual clearance
between two adjacent layers is `offset - depth-multiplier * depth` is invisible to anyone
authoring a figure. Export `depth-shear(d, depth-multiplier: 0.3)` and document the
clearance formula. This is the root cause of connections that appear to cross layer bodies:
a line descending into the apparent gap between two layers actually lands inside the
previous block's sheared top face whenever the gap is narrower than twice the shear.

*Test:* pure function, so the harness suffices. Assert `depth-shear(4.5) == 1.35`.

---

## Tier 2. Easy, self-contained

### 4. Connection z-order: `z: "behind" | "front"`

All user connections are drawn in a final pass after every layer box (`src/lib.typ:1712`),
so a skip route is unconditionally painted on top of anything it crosses. There is no depth
sorting. CeTZ 0.4.2 exports `draw.on-layer(layer, body)`, which assigns a `z-index` to
everything a body emits, so wrapping the connection body in `on-layer(-1, ...)` fixes the
entire class of defects without a depth-sorting rewrite. Default `"front"` preserves v0.3.

*Test:* three layers with one skip from L1 to L3 in `flat` mode at `pos: 0`, deliberately
routed straight through L2's body. Render twice, changing only `z`. Expect the line visible
across L2 with `"front"` and hidden behind it with `"behind"`.

### 5. Per-connection stroke styling: `stroke`, `dash`, `color`

Thread an optional style dict through `draw-segment-with-arrow` (`src/lib.typ:367`).
Defaults pull from the active palette. Residual adds, concat feeds, attention routes and
auxiliary supervision paths are semantically different and should be distinguishable.

*Test:* two skips with identical geometry, x-shifted only, one solid and one dashed.
Matching the routing isolates styling from layout.

### 6. Connection legend entries

Depends on 5. The legend currently knows only about layer boxes. Extend `legend-entries` to
accept line samples alongside colour swatches.

*Test:* the test from 5 plus `show-legend: true` and two named connection styles.

### 7. Group brackets: `groups: ((from: "p1", to: "p5", label: "Backbone"), ...)`

Backbone, neck and head are the phrases anyone uses to explain these diagrams, and there is
no way to draw them. All required geometry is already in `layer-positions` by the time the
connection loop runs. Draw a brace or tinted band spanning min-x to max-x below the stack.

*Test:* four layers with two groups covering layers 1-2 and 3-4. Then the edge cases: a
group spanning a single layer, and two adjacent groups, to confirm spans do not run
together.

### 8. Repeat notation: `repeat: N`

Depth-scaled models currently fake block repetition by stuffing extra entries into `widths`,
which is a visual coincidence rather than semantics. The package cannot label the repeat,
bracket it, or reflect it in the legend. Draw N ghosted slabs with a `xN` bracket.

*Test:* one layer with `repeat: 3` beside three separate entries at zero offset. The visual
comparison is itself the design decision.

---

## Tier 3. Moderate

### 9. Named anchors and `arrive-offset`

`touch-layer: true` resolves to exactly three arrival points per layer
(`src/lib.typ:1768-1782`), so a fourth connection must reuse one, and two connections in the
same mode land on the identical pixel with stacked arrowheads. Replace with a named-anchor
table (`"nw"`, `"w"`, `"sw"`, `"n"`, `"s"`, ...) plus a scalar offset along the chosen edge.
Retain `touch-layer: true` as an alias for current behavior. Fan-in to a concat node is
common enough to deserve first-class support.

*Test:* one target layer with three incoming skips, all on anchor `"nw"`, at
`arrive-offset: -0.3, 0, 0.3`. Expect three distinct, evenly spaced arrowheads.

### 10. `pos: auto` lane assignment

Depends on 9, since lane packing needs real arrival points. Collect each connection's
x-span, sort, and greedily assign the lowest non-conflicting lane. This is standard
interval-graph colouring and removes the hand-tuning that authoring a dense neck currently
requires.

*Test:* four skips with deliberately overlapping spans covering all three interval
relationships in one figure: one nested inside another, one partially overlapping, one
disjoint. Confirm the disjoint pair reuses a lane.

### 11. `shape: (channels, h, w)` auto-sizing

Highest backward-compatibility risk on the list, because it wants to touch the default
height and depth logic at `src/lib.typ:614-618`. Contain the risk by making `shape` a
strictly separate code path, so that absent `shape` nothing changes. Requires a documented
mapping, log-scaled channels to width and linear spatial extent to height and depth, with
configurable constants. Today nothing prevents drawing a 20-square block taller than an
80-square one.

*Test:* two blocks, one written as `shape: (256, 40, 40)` and one hand-sized to the values
the mapping should produce, rendered identically. Then a four-level pyramid to confirm the
scaling reads correctly across an order of magnitude.

---

## Tier 4. Hard, and the first gates the second

### 12. Extract the trunk walker into a reusable function

An enabling refactor rather than a user-facing feature. The layer loop
(`src/lib.typ:609-1664`) mutates implicit state, `prev-x` and `arrow-axis-y`, as it walks.
Factor the body into `walk-trunk(layers, start-x, axis-y) -> (positions, end-x)` that emits
as it goes. Behavior-identical by construction.

*Test:* the harness alone. Zero pixel change across all 15 examples is the entire acceptance
criterion for this step.

### 13. Parallel branches

Depends on 12 for the walker and 9 for off-axis anchors, and benefits from 4 so branch skips
can pass behind the trunk. `draw-network` walks a single list and advances one x-cursor, so
anything genuinely parallel must be collapsed into one box with arrows pointed at it. Three
detection heads, the two branches inside a CSP block, an Inception module, a two-stream
fusion network and a Siamese encoder are all currently undrawable as they actually are.

Add `(type: "branch", branches: (...), rejoin: "name")`, walking each sub-list at its own
y-offset and reconnecting at the named node.

*Test:* start with the smallest possible case, input into two single-layer branches into a
concat. Then add exactly one variable at a time in separate files: unequal branch lengths
(does the rejoin x-position take the max?), a skip crossing from a branch to the trunk, and
a nested branch.

---

## Sequencing notes

Do 4 before 9 and 10. Once connections can pass behind boxes, much of the routing pressure
that 9 and 10 exist to relieve disappears, and both features get designed against a more
forgiving baseline.

Do 12 before 11 even though 11 is nominally easier. Auto-sizing rewrites the same
default-geometry code that the walker refactor relocates, and the opposite order means
resolving that conflict twice.

## Known issues folded into the above

`mode: "depth"` on a connection routes the line backwards through the layer stack, which
appears unintended for anything but very short hops. Revisit while implementing 9.

The input image plane overlapping the first convolution block is *not* a defect. The
bundled `ResNet18` example does the same, layers are semi-transparent, and the overlap is
house style.

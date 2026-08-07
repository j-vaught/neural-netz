# neural-netz v0.4 Roadmap

Author: J.C. Vaught

Fork point: `fix/plotting-corners-and-arrows` @ `cb6334b` (corner-spike and arrowhead-transparency
fix already applied on top of `v0.3.0`).

This document is the working plan for v0.4. Items are ordered easiest to hardest, with
dependencies resolved so that a prerequisite always appears before anything that needs it.

## Status

| Item | State |
|---|---|
| Step 0. Regression harness | done |
| 1. Custom layer bandfill default | done, tag `v0.4-tier1.1` |
| 2. Label offsets, orientation and baseline anchoring | done |
| 3. Export a shear helper | done |
| 4. Connection z-order | next |

Everything from Tier 1 item 3 onward is untouched. The palette overhaul is planned but
deliberately out of scope for the items above.

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

*Test:* the exact assertion suggested here does not hold. `0.3` has no exact binary
representation, so `depth-shear(4.5)` is `1.3499999999999999`. Compare with a tolerance.
Rounding inside the library would be worse, since the value feeds coordinates rather than
being displayed. The test also carries a visual pair, one figure at `offset: depth-shear(6)`
where the descent crosses the previous layer, one at `min-clear-offset(6)` where it clears.

---

## Tier 2. Easy, self-contained

### 4. Connection z-order: `z: "behind" | "front"` -- implemented, then reverted

All user connections are drawn in a final pass after every layer box (`src/lib.typ:1712`),
so a skip route is unconditionally painted on top of anything it crosses. There is no depth
sorting. CeTZ 0.4.2 exports `draw.on-layer(layer, body)`, which assigns a `z-index` to
everything a body emits, so wrapping the connection body in `on-layer(-1, ...)` fixes the
entire class of defects without a depth-sorting rewrite. Default `"front"` preserves v0.3.

**Do not rebuild this without asking.** It was implemented in `f7d0e2e` and reverted in
`32bf8b7` by preference, not because it failed. Routing over the top of the stack is the
house style here, as it is in PlotNeuralNet and in the bundled U-Net example, so a route
passing behind a block is not wanted even when it is drawn correctly. The revert is the
decision, not a rollback of a broken feature.

Consequences for the rest of the plan. Crossings are not the pain point; lanes are. Every
connection routed over the top needs its own height, those numbers are picked by eye, and
they all shift when a connection is added. That makes item 10, `pos: auto`, the highest
value item left rather than a mid-tier one. Its stated dependency on item 9 is softer than
written: lane packing needs each connection's x-span, which is already known, so a first
version can ship before named anchors exist.

If it is ever revived, the working implementation is in `f7d0e2e`. Two things it got right
that a reimplementation would have to repeat: CeTZ's `on-layer(-1, body)` avoids a
depth-sorting rewrite entirely, and the connection label must be emitted outside the layered
content, since `on-layer` moves everything a body emits and the label otherwise washes out
against the layer fill.

### 5. Per-connection stroke styling: `color`, `dash`, `thickness`

Thread an optional style dict through `draw-segment-with-arrow` (`src/lib.typ:367`).
Defaults pull from the active palette. Residual adds, concat feeds, attention routes and
auxiliary supervision paths are semantically different and should be distinguishable.

Shipped as three orthogonal keys rather than the `stroke`/`dash`/`color` mix named here.
Flat keys match how the rest of the API reads, let a dash be set without restating paint and
thickness, and avoid reusing `stroke`, which already means a plain colour on the sum node.

`thickness` multiplies the palette width instead of replacing it, so figures passing
`stroke-thickness` to `draw-network` keep scaling. Arrowheads take the line colour.

*Test:* four skips with identical geometry, shifted along the axis, differing only in style.
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

### 10. `pos: auto` lane assignment -- done, ahead of its tier

Brought forward because routing over the top is the house style, which makes lanes the
recurring cost rather than crossings. The stated dependency on item 9 did not hold: packing
needs each connection's x-span, which `layer-positions` already carries, not its arrival
anchor.

Two parts. A route asking for `auto` is placed clear of the tallest layer in the figure,
using a reach accumulated during the drawing pass, so the author no longer has to derive a
clearing height from layer dimensions. Routes are then packed by the usual greedy: sort by
start, take the lowest lane whose previous occupant has finished.

Note that consecutive skips sharing an endpoint layer do land in different lanes. Their
spans genuinely touch, and the descent of one meets the ascent of the next at the same x, so
that is correct rather than conservative.

Original note follows.

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

## Deliberate default changes

These intentionally break pixel compatibility with v0.3 and required a full re-baseline.
They are listed separately from the feature tiers because the governing rule above does not
apply to them: the whole point is that the default look changes.

### Arrows and connections are black

`arrow` and `connection` were `#0f4d52` in both palettes, a dark teal. Both are now
`#000000`. This affects every figure, though in most of them only as a thin band along the
axis.

### The sum node is a flat white disc with a black outline

It was a green disc filled with a radial gradient, the only object in the library rendered
with gradient shading, which read as a glossy bead against otherwise flat isometric slabs.
It is now drawn flat, white, with an explicit black ring and symbol, which is the
convention used in the ResNet paper and in PlotNeuralNet.

The outline is taken from a new palette entry `sum-stroke` rather than derived from the
fill. Deriving it applies `darken(50%).saturate(80%)` (`src/lib.typ:73`), and pushing
saturation on a near-neutral fill amplifies incidental hue, which turned a white node's
ring an arbitrary maroon.

`fill`, `stroke` and `symbol` are all per-layer overrides, so the previous filled look
remains reachable. Legend entries now accept an optional `stroke` for the same reason, since
a white swatch would otherwise pick up the same derived tint.

### Layer labels are anchored on the baseline

CeTZ measures content from cap-height to baseline and then grows that box by the actual
glyph bounds (`shapes.typ:1092-1096`). A label containing descenders therefore gets a taller
box, and centring it lifts the text: measured on a controlled figure, "pppp" sat 3px above
"nnnn" and "llll" at 200 ppi, roughly 1pt. Labels now use CeTZ's `base` anchor, which pins
the baseline directly, so alignment no longer depends on which ascenders and descenders a
string happens to contain.

Side effect: every label sits about 1.8pt closer to its block than in v0.3, uniformly. A
compensating offset was considered and rejected, since the correction would have to scale
with both font size and the `scale` argument to stay correct.

Note for future work: a zero-width strut was tried first and does nothing here. `measure()`
returns a constant height for every string at a given size, so there is no bounding box to
equalise.

Two shadowing traps, both from `import draw: *` (`src/lib.typ:168`), which pulls CeTZ's
whole draw namespace into scope. CeTZ defines its own `hide` and its own `rotate`, so the
Typst ones must be reached as `std.hide` and `std.rotate`. Both failed silently rather than
erroring: the CeTZ `hide` drew the strut visibly, and the CeTZ `rotate` panicked only
because it happened to reject the `reflow` argument.

Rotated labels go through `std.rotate(..., reflow: true)` rather than CeTZ's `angle:`
argument on `content()`. `angle:` rotates the text about its anchor, which leaves a vertical
label roughly half a cap-height off centre from its layer; `reflow` gives the rotated text a
real bounding box that a normal anchor acts on, so `"north"` centres it by construction.

## Known issues folded into the above

`mode: "depth"` on a connection routes the line backwards through the layer stack, which
appears unintended for anything but very short hops. Revisit while implementing 9.

The input image plane overlapping the first convolution block is *not* a defect. The
bundled `ResNet18` example does the same, layers are semi-transparent, and the overlap is
house style.

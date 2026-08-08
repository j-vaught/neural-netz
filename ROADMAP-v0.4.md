# neural-netz v0.4 Roadmap

Author: J.C. Vaught

Fork point: `fix/plotting-corners-and-arrows` @ `cb6334b` (corner-spike and arrowhead-transparency
fix already applied on top of `v0.3.0`).

This document is the working plan for v0.4. Items are ordered easiest to hardest, with
dependencies resolved so that a prerequisite always appears before anything that needs it.

## Status

Released as 0.4.0. Each done item carries a `v0.4-tier*` tag.

| Item | State |
|---|---|
| Step 0. Regression harness | done |
| 1. Custom layer bandfill default | done |
| 2. Label offsets, orientation and baseline anchoring | done |
| 3. Exported shear helpers | done |
| 4. Connection z-order | implemented, reverted by preference |
| 5. Per-connection stroke styling | done |
| 6. Connection legend entries | done |
| 7. Group brackets | done |
| 8. Repeat notation | done |
| 9. `arrive-offset`, manual and auto | done |
| 10. `pos: auto` lane assignment | done, early |
| 11. `shape:` auto-sizing | done |
| 12. Trunk walker extraction | done |
| 13. Parallel branches, vertical and depth modes | done |
| 14. Junction dots on connections, crowding diagnostics | implemented, withdrawn on review |
| 15. `offset: auto` | done, unplanned |

Not yet done, flagged along the way: `spread: auto` for branches, branch-aware label
placement, the legend position on deep final layers, range-repeat, departure-side
arrive-offset, and the palette overhaul.

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

Entries carry `kind: "line"` and render as a stroke sample with a head rather than a filled
swatch. The sample column widens whenever a line entry is present: at swatch width a dash
pattern has no room to show, so a dashed entry looked identical to a solid one. Layer
swatches widen with the column, or they float away from their labels, which only became
obvious on a legend with several layer types.

The sample line stops short of its arrowhead rather than running to the tip. The head is
concave behind its widest point, so a line ending further forward shows its end cap inside
that notch, most visibly on a thick stroke. The line ends `0.75 * triangle-size` behind the
head centre, chosen by eye against the 2x-thickness case: `0.9` sits exactly at the barbs and
covers most, but reads as a slightly loose join at normal weights.

`main-legend` on `draw-network` names the automatic axis arrows. It defaults to `none`, so
existing figures are unchanged, but a legend that explains every skip and omits the forward
pass is arguably incomplete: worth considering as a default.

*Test:* the styling test plus `show-legend: true` and four named connection styles.

### 7. Group brackets: `groups: ((from: "p1", to: "p5", label: "Backbone"), ...)`

Backbone, neck and head are the phrases anyone uses to explain these diagrams, and there is
no way to draw them. All required geometry is already in `layer-positions` by the time the
connection loop runs. Draw a brace or tinted band spanning min-x to max-x below the stack.

Drawn as a square bracket, not a brace: everything else in the package has flat edges, and a
brace would be the only curve on the page.

Placement needs the lowest point any route reaches, not just the tallest layer. The first
version measured from layer extent alone and the YOLO neck bracket landed on top of a skip
routed beneath the stack. Routes running underneath are now tracked during the connection
pass and brackets sit below them.

*Test:* four layers with two groups covering layers 1-2 and 3-4. Then the edge cases in one
figure: a group spanning a single layer, two adjacent groups, and an enclosing group pushed
to its own row with `offset`.

### 8. Repeat notation: `repeat: N`

Depth-scaled models currently fake block repetition by stuffing extra entries into `widths`,
which is a visual coincidence rather than semantics. The package cannot label the repeat,
bracket it, or reflect it in the legend. Draw N ghosted slabs with a `xN` bracket.

Drawn as a bracket above the block carrying the count, in the same visual vocabulary as the
group brackets from item 7.

Four depictions were prototyped and rejected before settling on it. Outlined ghost copies
read as empty boxes rather than as more of the same block, and the up-right offset reads as a
drop shadow. Filled ghosts are better but cannot take the block's own colour, since the fill
lives inside each layer type's branch and is not visible where the repeat is drawn. A
subdivided bracket lets the count be read off the drawing, but stops working past about ten
and invites reading the ticks as sub-block boundaries. A dashed enclosure says "this region
repeats", which is the right reading only if a repeat can span several layers, and that would
be a different feature.

The bracket spans the block's top face. Spanning the full footprint from the front-left
corner was tried and looked heavier than the block warrants.

`repeat` describes one layer entry, not a run of them, so a repeated pair such as
`(conv, pool)` or `(attention, mlp)` cannot be expressed. A stage ending in a pool is written
by splitting it: two plain blocks carry the repeat and the third is drawn on its own with the
pool attached, which also keeps the bracket over a block with nothing attached to it. A
repeat spanning a range of layers would be a separate feature, closer to the group brackets
than to this one.

Implemented without touching each layer type. The block's drawn width is recovered from how
far the drawing cursor moved across the type dispatch, so `repeat` works on any block rather
than only the ones taking `widths`.

The stack claims the width it occupies, advancing both the cursor and `prev-x`. Without that
the next layer is drawn over the ghosts, and an attached pool, which positions itself from
the block's right edge, lands on them.

Ignored on `pool`, `unpool` and `sum`. The first two attach to the block before them, so the
cursor does not describe their own footprint, and repeating a modifier is not meaningful
anyway.

*Test:* the same architecture faked with three `widths` entries and declared with `repeat: 3`,
so the comparison is visible. Then counts from 2 to 6 across block types, and the ignored
case.

---

## Tier 3. Moderate

### 9. `arrive-offset` -- done, without the named-anchor table

Shipped as an offset alone. A named-anchor table of `nw`, `n`, `w`, `sw`, `s` was built first
and removed: the names describe positions on an isometric slab, where on a thin block such as
a concat, the very block a fan-in targets, `nw` and `n` land within a few pixels of each
other. Five names for three usable points is a vocabulary that does not earn itself.

`touch-layer` already selects a side from the routing mode, so `arrive-offset` spreads along
that same edge and no second vocabulary is needed. The offset runs along the edge rather than
in x, since the top and bottom edges of the west side follow the isometric depth direction.

Terminating arrowheads were also tried, drawing the head at the arrival point rather than
mid-segment, and reverted. Mid-segment heads are the convention throughout the package and
the inconsistency was not wanted.

A route arriving on the bottom or left edge has its final stretch drawn behind the layer.
Those edges are on the far side of the block, so the route passes underneath it before
reaching them, and drawing that stretch on top made it read as running across the front face.
The layers are already semi-transparent, so it ghosts rather than vanishing, with no extra
shading logic. Scoped to the final segment of a non-air `touch-layer` arrival, so it is not
the general route-behind-blocks behaviour that item 4 was reverted for.

Depth arrivals needed no feature at all. Several routes converging on one point and looping
in is simply what happens when none of them sets an offset, and ordering by reach falls out
of `pos: auto`. Fanning along the left edge was prototyped and rejected: that face recedes, so
a fan there sweeps across the figure, whereas the top and bottom edges run parallel to the
lanes and fan cleanly. A junction marker at the convergence was also prototyped and rejected.

Arrival is still the only side handled. Departure stays the arrow-segment midpoint or the
`touch-layer` edge, since the stacking problem is fan-in: several routes converging on one
concat, not several leaving one block.

`arrive-offset: auto` spaces a fan automatically, the same shape of problem as item 10's lane
packing: group by the edge a route lands on, then spread across it. `k` routes divide the edge
into `k + 1` intervals and sit at the interior boundaries, inset rather than on the corners,
ordered by where each route starts so the fan does not cross itself.

This also produces the capacity number item 14 needs. The arrival edge is
`sqrt(2) * depth * depth-multiplier` for top and bottom arrivals and the layer height for
left ones, so how many routes a layer can accept is computable rather than a matter of
eyeballing a tangle.

*Test:* three routes hand-spaced, the same three on auto for comparison, and five on auto to
show a fan respacing rather than needing every offset re-picked.

### 10. `pos: auto` lane assignment -- done, ahead of its tier

Brought forward because routing over the top is the house style, which makes lanes the
recurring cost rather than crossings. The stated dependency on item 9 did not hold: packing
needs each connection's x-span, which `layer-positions` already carries, not its arrival
anchor.

A route asking for `auto` is placed clear of the tallest layer in the figure, using a reach
accumulated during the drawing pass, so the author no longer has to derive a clearing height
from layer dimensions.

Height then comes from how far a route reaches, not from packing order. Interval packing was
tried first and rejected: the greedy hands the lowest lane to whichever route starts first,
which is usually the longest, so the enclosing route ended up beneath the routes it encloses
and they had to cross. Ordering by reach means a longer route always arcs over a shorter one,
and equal reaches share a height, which reads as a group.

Reach is ranked rather than used directly. Literal proportionality was tried and rejected
too: a seven-block route among two-block ones left four empty lanes and grew the figure by
about 40% in height for no information gained.

Equal reach with overlapping spans is the one conflict. Those are resolved by sending the
second route to the opposite side of the axis at the same height, rather than stacking it
higher, so neither is pushed further out than its reach warrants. Only a third overlapping
route of the same reach needs a new height.

`lane-unit` on `draw-network` sets the spacing between heights.

Original note follows.

Depends on 9, since lane packing needs real arrival points. Collect each connection's
x-span, sort, and greedily assign the lowest non-conflicting lane. This is standard
interval-graph colouring and removes the hand-tuning that authoring a dense neck currently
requires.

*Test:* four skips with deliberately overlapping spans covering all three interval
relationships in one figure: one nested inside another, one partially overlapping, one
disjoint. Confirm the disjoint pair reuses a lane.

### 11. `shape: (channels, h, w)` auto-sizing

The mapping stated here, log-scaled channels to width and **linear** spatial extent to height
and depth, is wrong on the second half. Linear puts a 20-square block a quarter of a unit tall
against 8 for a 640-square input. Both axes are logarithmic. Fitted against the pyramid in the
YOLO example, tuned by eye earlier in this work, `1.2 * log2(spatial) - 3.2` reproduces its
heights to within 0.4 units and `0.075 * log2(channels)` its widths to within 0.05, which is
independent confirmation that a log mapping is what one converges on by hand.

Constants are absolute rather than normalised across a figure, so the same shape gives the
same size everywhere and two figures in one document stay comparable. Normalising was
considered and rejected: it would resize every block whenever a layer is added, which is
tolerable for invisible scaffolding like lanes and jarring for the blocks themselves.

Shape supplies defaults, not values, applied field by field, which is what keeps manual
control. Absent `shape` the code path never runs.

Highest backward-compatibility risk on the list, because it wants to touch the default
height and depth logic at `src/lib.typ:614-618`. Contain the risk by making `shape` a
strictly separate code path, so that absent `shape` nothing changes. Requires a documented
mapping, log-scaled channels to width and linear spatial extent to height and depth, with
configurable constants. Today nothing prevents drawing a 20-square block taller than an
80-square one.

*Test:* two blocks, one written as `shape: (256, 40, 40)` and one hand-sized, verified
pixel-identical. The hand-sized one has to spell out the mapping rather than round it:
writing 3.186 for 3.18631... shifts the edges by a fraction of a pixel and shows in a diff.
Then a 640-to-20 pyramid, the per-field overrides, and a non-square pair.

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

## Tier 4 (continued)

### 14. Junction points, and refusing to draw an impossible junction -- withdrawn

**Do not build this without asking.** It was implemented once, working, and rolled back on
request before commit: dots at every point a connection attaches to a main-axis arrow, plus
a crowding check ringing an over-full arrival edge in red by default and panicking under
`strict: true` with the layer name, the count, the capacity at `junction-sep` spacing, and
the depth or height that would fit the fan. The strict message read, for example: 5 routes
arrive on the top edge of "cat", which fits 1 at spacing 0.5; give it depth at least 7.07 or
reduce the fan.

The branch junction dots from item 13 are unaffected and remain: those mark a branch's own
split and merge. What was withdrawn is extending that grammar to ordinary connections, and
the crowding validation on top of it.

Original proposal follows for context.

Two related changes to how a connection meets the main axis.

First, the visual grammar. A route currently runs straight into the arrowhead it departs from
or arrives at, so the meeting point is wherever the stroke happens to cross the head. Drawing
a small filled circle at the junction instead would make the attachment explicit and would
stop the route and the arrowhead fighting over the same pixels. Item 4's revert and the
anchored-head redraw are both workarounds for that overlap; a junction marker removes the
overlap rather than papering over it.

Second, and more valuable, validation. Once junctions are explicit objects with a size, the
package can check whether the ones a figure asks for actually fit. Six connections meeting
the axis between the same pair of blocks cannot be drawn legibly however they are ordered,
and today that silently produces a tangle. It should instead be a diagnosable condition:
name the pair of layers, say how many junctions were requested, and say how much wider the
gap has to be. `min-clear-offset` (item 3) already computes the geometry side of that, so the
required width is derivable rather than guessed.

The interesting design question is what to do when it fails. A hard error stops a document
build over a cosmetic problem, which is harsh for something that still renders. A warning
that is easy to miss is close to useless. A third option is to draw it, mark the crowded
junction visibly, and report, so the figure still compiles but the problem is impossible to
overlook.

Depends on item 9 for named anchors, since several routes meeting one junction need distinct
arrival points, and shares machinery with item 10's lane packing, which already computes
which connections compete for the same span.

### 15. `offset: auto`

Not originally planned. It came out of converting the YOLO example to `shape`: with sizes
derived, the figure still had to compute its own offsets, which meant exporting the sizing
mapping so a figure could restate it. That was the wrong shape of fix. Both inputs to the
spacing rule are already known inside `draw-network`, the previous layer's depth and whether
the connection list names a layer as a target, so the figure should not be computing either.

The example lost its entire spacing preamble, six size constants and two helper functions,
and with it the hazard that the pyramid was written down twice with nothing to catch the two
copies drifting apart.

Pool and unpool needed separate handling: they position themselves from their own offset
rather than from the layout cursor, in three places, so `auto` is resolved for them too
rather than being treated as unset. Treating it as unset collapsed them onto their
neighbours.

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

### Connections route over the top by default

`mode` defaulted to `"flat"`, which routes a connection underneath the stack. It now defaults
to `"air"`, over the top, which is the convention in PlotNeuralNet and in most published
diagrams and is the house style here.

No bundled example relied on the default; every one of them names its mode explicitly, so
only the two connection test cases changed.

Note that this is separate from draw order, which is what the anchored-head redraw addresses.
Where a route runs is one question; which of the route and the arrowhead is painted second is
another.

## Known issues folded into the above

`mode: "depth"` on a connection routes the line backwards through the layer stack, which
appears unintended for anything but very short hops. Revisit while implementing 9.

The input image plane overlapping the first convolution block is *not* a defect. The
bundled `ResNet18` example does the same, layers are semi-transparent, and the overlap is
house style.

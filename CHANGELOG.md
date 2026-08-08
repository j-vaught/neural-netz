# Changelog

## 0.4.0

This fork release extends [neural-netz 0.3.0](https://github.com/edgaremy/neural-netz) by
Edgar Remy. Every feature below is opt-in with defaults reproducing 0.3 behaviour, except
where listed under "Changed defaults". A golden-image regression harness in `tests/` guards
that claim.

### Parallel branches

- `(type: "branch", branches: (...))` draws genuinely parallel sub-networks: three detection
  heads, CSP interiors, two-stream fusions. Branches nest.
- `spread-mode: "vertical"` (default) stacks branches above and below the trunk;
  `"depth"` stacks them along the projection's 45-degree axis as a parallelogram of two
  parallel spines with horizontal teeth.
- Both modes centre on the trunk: an odd count puts one branch on the trunk line, an even
  count leaves it empty.
- Filled dots mark junctions where flow divides, meets, or leaves a spine that passes
  through. Merging routes terminate at the dot; a single arrow continues to the next block.
- Named branch layers are full citizens: connections, groups and automatic lane ranking all
  reach them, and connections land on a branch's entry tooth at its arrowhead.

### Sizing and spacing from the architecture

- `shape: (channels, height, width)` derives a layer's geometry from its tensor shape,
  logarithmically on both axes, overridable field by field. Constants via `shape-scale`.
- `offset: auto` spaces layers from the drawing itself: it covers the previous block's
  isometric lean and widens where a connection descends into the gap. `auto-gap` sets the
  visible white space.
- `depth-shear` and `min-clear-offset` are exported for figures that compute their own
  geometry.
- The bundled YOLO26-n example is written entirely this way: shapes and `auto` throughout,
  with a depth-mode three-head Detect branch.

### Connections

- Per-connection `color`, `dash` and `thickness` (a multiplier, so `stroke-thickness`
  still scales). Arrowheads take the line colour. Corner stubs match the route's style.
- `legend` on a connection adds a line-sample legend entry; `main-legend` on `draw-network`
  names the automatic axis arrows.
- `pos: auto` assigns lane heights from how far a route reaches: longer routes arc over
  shorter ones, equal reaches share a height, and two overlapping equals split across the
  axis. `lane-unit` sets the spacing.
- `arrive-offset` fans several `touch-layer` arrivals along the target's edge;
  `arrive-offset: auto` spaces a whole fan evenly. Arrivals on far-side edges draw their
  final stretch behind the layer.
- Extra connections default to `mode: "air"`, over the top.

### Annotation

- `groups` draws labelled square brackets under spans of layers, stackable and tintable,
  placed clear of routes running beneath the figure.
- `repeat: N` marks a block as repeated in series with a bracket and count.
- `label-orient` presets (`horizontal` / `diagonal` / `vertical`) with correct anchoring;
  `label-dx` / `label-dy` / `label-anchor` / `label-angle` for manual control. Labels anchor
  on the baseline, so descenders no longer shift a label out of line.

### Changed defaults (deliberate breaks with 0.3)

- Arrows and connections are black rather than dark teal.
- The sum node is a flat white disc with a black outline and symbol rather than a green
  radial-gradient sphere. `fill`, `stroke` and `symbol` are per-layer overrides.
- A `custom` layer shows an activation band only when it declares a `bandfill` or opts in
  with `show-relu`; an undeclared band colour derives from the layer's own fill.
- Layer labels sit ~1.8pt closer to their blocks (baseline anchoring).

### Internals

- The layer walk is extracted into `walk-trunk`, which is what makes branches possible.
- `tests/` carries a golden-image harness (`bless.sh`, `regress.py`) covering every bundled
  example and a per-feature test suite.

## 0.3.0

See the [upstream release](https://github.com/edgaremy/neural-netz/releases) for earlier
history.

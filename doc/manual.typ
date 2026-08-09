#import "manual-lib.typ": *

#set document(title: "The neural-netz manual", author: "J.C. Vaught")
#set page(
  paper: "a4",
  margin: (x: 2.6cm, y: 2.4cm),
  numbering: "1",
  number-align: center,
)
#set text(size: 10pt, lang: "en", hyphenate: true)
#set par(justify: true, leading: 0.62em)
#show raw: set text(font: "DejaVu Sans Mono")
// Inline code is unbreakable, so at body size a long identifier such as
// `connection-label` overhangs the measure. A touch smaller keeps it inside.
#show raw.where(block: false): set text(size: 0.88em)
#show link: set text(fill: atlantic)

#set heading(numbering: "1.1")
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  block(above: 0pt, below: 16pt, {
    text(size: 8pt, fill: garnet, weight: "bold", tracking: 1.2pt,
      upper[Chapter #counter(heading).display("1")])
    v(2pt)
    text(size: 20pt, weight: "bold", it.body)
    v(3pt)
    line(length: 100%, stroke: 1.5pt + garnet)
  })
}
#show heading.where(level: 2): it => block(above: 16pt, below: 8pt,
  text(size: 12.5pt, weight: "bold", fill: garnet, it))
#show heading.where(level: 3): it => block(above: 12pt, below: 6pt,
  text(size: 10.5pt, weight: "bold", it.body))

#set page(numbering: none)
#align(center)[
  #v(3cm)
  #text(size: 30pt, weight: "bold")[neural-netz]
  #v(2pt)
  #text(size: 13pt, fill: grey-70)[Neural network diagrams in Typst]
  #v(1.4cm)
  #block(width: 78%, image("build/types-overview.pdf", width: 100%))
  #v(1.4cm)
  #text(size: 10pt)[Version 0.4 · J.C. Vaught · after Edgar Remy's neural-netz 0.3]
  #v(4pt)
  #text(size: 9pt, fill: grey-70)[Every figure in this manual is compiled from the code printed beside it.]
]

#pagebreak()
#set page(numbering: "1")
#counter(page).update(1)

#outline(depth: 2, indent: 1.2em)

= What this is

neural-netz draws neural network architectures as isometric block diagrams, the
kind that open a paper's method section. It is a Typst package built on
#link("https://typst.app/universe/package/cetz/")[CeTZ], and its visual style
comes from #link("https://github.com/HarisIqbal88/PlotNeuralNet")[PlotNeuralNet].

You describe the network as a list of layers. The package works out the
geometry, the spacing, the arrows between blocks, the routing of any skip
connection you add, and the legend.

#ex("first-figure", fig-width: 78%,
  caption: [Three convolutions, no options. Sizes, spacing and arrows are all defaults.])

== How this manual is organised

Every feature is shown on its own, in the smallest figure that demonstrates it.
There are no worked architectures here on purpose: complete models --- AlexNet,
VGG, ResNet, U-Net, FCN-8, YOLO26-n and six RGB-IR fusion variants --- live in
`examples/` in the repository, where you can read them as whole files rather
than as fragments. This manual is for finding out what a single option does.

Chapters 2 to 5 cover a layer and its geometry. Chapters 6 to 9 cover everything
written on or around a block. Chapters 10 to 13 cover the structures between
blocks: connections, groups and parallel branches. Chapter 14 covers the figure
as a whole, and chapter 15 lists every option in one place.

== Installing

#snippet(```typ
#import "@preview/neural-netz:0.4.0": draw-network, conv, pool, input
```)

Every example in this manual assumes an import like that one. Import
`draw-network` plus whichever layer constructors you use, or take the lot with
`: *`.

#warn[
  Version 0.4 is a fork and is not yet on Typst Universe, where the name
  `neural-netz` currently resolves to Edgar Remy's 0.3.0. Until it is published,
  point the import at a local copy: `#import "path/to/src/lib.typ": *`.
]

= Writing a layer

A network is an array of layers, passed to `draw-network`. A layer is a
dictionary with a `type` and whatever options you want to set:

#ex("two-forms-dict", fig-width: 88%)

Every type also has a constructor, which is the same thing with the `type`
filled in:

#ex("two-forms-ctor", fig-width: 88%)

Those two produce identical figures. Prefer the constructor form: its signature
is exactly the set of options that type accepts, so an editor can list them
while you type, and Typst rejects a misspelled argument by name before the
package ever sees it. The dictionary form stays supported everywhere, including
inside `branches`, and the two mix freely in one figure.

== Options that do not exist are errors

An option a layer type does not read is rejected, not ignored:

#snippet(```
error: unknown layer option "hieght" on layer 3 (type "conv").
Did you mean "height"? Options accepted here: bandfill, channels,
connection-label, depth, fill, height, image, label, ...
```)

This matters more than it sounds. A key that is quietly ignored produces a
figure that is merely wrong, and a wrong figure reads as the package being
broken rather than as the typo it is. The check covers layer options, connection
options, group options, unknown layer types, a layer with no `type`, and a
connection or group naming a layer that has no such `name`.

#note[
  The suggestion comes from an edit-distance search over the options that type
  actually accepts, so `widths` on a `pool` is caught as readily as `hieght` on
  a `conv` --- the first is spelled correctly and still means nothing there.
]

== Naming a layer

Give a layer a `name` and other things can refer to it. Connections and groups
both work by name, and nothing else does; a layer with no name is drawn and
forgotten. Names are yours to choose and appear nowhere in the output.

= Layer types

Fourteen types are predefined. Each carries a colour, a default size, a default
legend entry, and in a few cases a behaviour.

#ex-wide("types-overview", fig-width: 96%, fig-height: 7cm,
  caption: [`conv`, `convres`, `deconv`, `concat`, `gap`, `fc`, `sum`, `softmax`, `output`. Also predefined: `input`, `pool`, `unpool`, `convsoftmax`, `custom`.])

Type governs colour and defaults, not capability. Any type can be resized,
recoloured, relabelled and given an image. If you want a block the package has
no name for, use `custom` (chapter 9) rather than bending an unrelated type to
fit.

== Pooling attaches to the block in front

`pool` and `unpool` are the two types that are not free-standing blocks. They
position themselves against the layer before them, which is what makes a
convolution-plus-pool read as one stage. Give one an `offset` and it detaches:

#ex-wide("type-pool", fig-width: 78%, fig-height: 5cm)

== The sum node

`sum` is a node rather than a block: it has a `radius` instead of a width, and a
`symbol` you can replace.

#ex("type-sum", fig-width: 76%)

== The input layer

`input` defaults to a flat plane with no thickness, which is what an image is.
Chapter 8 covers putting a picture on it.

#ex("type-input", fig-width: 72%)

= Sizing a block

A block has three dimensions. `height` and `depth` are the spatial extent of the
tensor; `width` (or `widths`) is its thickness, which by convention means
channel count.

#ex("size-manual", fig-width: 100%)

== Several bands in one block

`widths` takes an array, and draws one band per entry inside a single block.
That is how a stage of two or three convolutions at the same resolution is
usually drawn: one block, banded, rather than three blocks in a row.

#ex("size-widths", fig-width: 100%)

== Flat layers

`depth: 0` draws a plain rectangle rather than a prism, which suits a
fully-connected layer, where there is no spatial extent left to depict.

#ex("size-2d", fig-width: 62%)

== Sizing from the tensor shape

Stating three numbers per block and keeping them consistent across a pyramid is
the tedious part of drawing one of these. `shape` takes the tensor the layer
produces, as `(channels, height, width)`, and derives the geometry from it:

#ex-wide("size-shape", fig-width: 88%, fig-height: 8cm)

Both axes are logarithmic:

$ "height", "depth" = 1.2 log_2("spatial") - 3.2, quad "width" = 0.075 log_2("channels") $

Linear spatial extent does not work. Across a 640-to-20 pyramid it puts the
smallest block at a quarter of a unit against 8 for the input, which is
invisible.

`shape` supplies defaults, not values. Anything you state explicitly wins, field
by field, so a block can take its width and depth from its shape while its
height is forced:

#ex("size-shape-override", fig-width: 88%)

The constants are absolute rather than normalised across a figure, so the same
shape gives the same size everywhere and two figures stay comparable. Change
them with `shape-scale` on `draw-network`, which takes a slope and an intercept
for each axis, applied to the base-2 logarithm:

#ex-wide("size-shape-scale", fig-width: 62%, fig-height: 5cm)

#note[
  Only `conv`, `convres` and `custom` take a derived width, because only those
  three use thickness to mean channel count. The others have a fixed thickness
  that says something else, and keep it.
]

= Spacing

`offset` is the gap between a layer and the one before it. It defaults to
`auto`, which computes the gap from the drawing rather than from a constant:

#ex("spacing-auto", fig-width: 88%)

Automatic spacing covers the previous block's isometric lean, adds a fixed strip
of white space, and widens where a connection descends into the gap. A layer
drawn in isometric projection leans right by `depth × depth-multiplier`, so a
gap narrower than that lean buys no visible space at all --- which is why a
constant offset works for one size of block and fails for the next.

Set the strip of white space with `auto-gap` on `draw-network`:

#ex("spacing-auto-gap", fig-width: 88%)

== Spacing by hand

A number overrides the automatic gap for one layer, and means what it always
meant:

#ex("spacing-number", fig-width: 100%)

Two helpers are exported for figures that compute their own geometry:

#snippet(```typ
depth-shear(6)       // 1.8 -- how far a depth-6 block leans right
min-clear-offset(6)  // 3.6 -- smallest gap a connection can descend into
```)

A connection descending between two blocks arrives at the midpoint of the arrow
joining them, so it clears the lean only when half the offset exceeds it. That
is what `min-clear-offset` returns, and what automatic spacing applies for you.

#note[
  Both take a `depth-multiplier` argument, which must match the one passed to
  `draw-network`. The default multiplier of `0.3` has no exact binary
  representation, so `depth-shear(4.5)` is `1.3499999999999999`. Compare with a
  tolerance, if you compare at all.
]

= Labels

`label` names a block, beneath it.

#ex("label-basic", fig-width: 82%)

== Channel numbers

`channels` prints numbers along the top of a block, one per band. One extra
entry beyond the number of bands becomes the diagonal axis label instead, which
is where the spatial resolution usually goes.

#ex("label-channels", fig-width: 100%)

Strings work as well as numbers, so `channels: ("", "1/16")` labels the axis and
nothing else.

== Axis labels

`xlabel`, `ylabel` and `zlabel` name the three axes of one block, for the
figure that has to explain the projection itself.

#ex("label-axes", fig-width: 52%, fig-height: 5cm)

== Labelling the arrow between two blocks

`connection-label` sits on the axis arrow *after* the layer that declares it.

#ex("label-connection", fig-width: 82%)

== Where a label sits

Labels sit at a fixed spot beneath each block, so long labels on closely spaced
blocks collide. Rather than spreading the blocks apart to solve a typesetting
problem, move the label. `label-orient` has three presets:

#ex-wide("label-orient", fig-width: 76%)

Each preset pairs its angle with the anchor that places it correctly, so a
diagonal label points its end at its own block and a vertical one hangs centred
beneath it, with no manual adjustment. Rotating trades horizontal space, which
is scarce, for vertical space, which is usually free.

For anything else there are `label-dx`, `label-dy`, `label-anchor` and
`label-angle`:

#ex-wide("label-manual", fig-width: 82%)

Labels are anchored on their baseline rather than on their bounding box, so a
label with descenders sits level with one without. Use `"base-east"` and
`"base-west"` to anchor horizontally while keeping that alignment.

#warn[
  Setting both `label-orient` and `label-angle` is an error, and `label-orient`
  accepts only `"horizontal"`, `"diagonal"` and `"vertical"`. For any other
  angle use `label-angle` and pick `label-anchor` yourself, since the right
  anchor for an arbitrary rotation depends on where you want the text to sit.
]

= Images inside blocks

`image` puts content on a block's face, sheared to match the projection. The
string `"default"` uses the bundled photograph:

#ex("image-default", fig-width: 72%)

Any Typst image works:

#ex-wide("image-custom", fig-width: 54%, fig-height: 5cm)

And it does not have to be an image. Any content is accepted, which is useful
for putting an operator symbol on a block:

#ex("image-content", fig-width: 66%)

= Colour

`fill` sets a block's colour and `opacity` how solid it is. Edge colours are
derived from the fill, so a recoloured block stays internally consistent.

#ex("color-fill", fig-width: 88%)

#ex("color-opacity", fig-width: 88%)

== Activation bands

A darker band at the end of a convolution conventionally marks the activation.
Turn them on for a figure with `show-relu: true` on `draw-network`, and override
per layer:

#ex-wide("color-relu", fig-width: 88%)

An undeclared band colour is derived from the layer's own fill, so a recoloured
block gets a band that matches it rather than one from the palette.

== Palettes

Two palettes ship with the package, `"warm"` (the default) and `"cold"`.

#ex("palette-warm", fig-width: 88%)
#ex("palette-cold", fig-width: 88%)

A palette sets the defaults only. Any `fill` you state wins, so a figure can sit
on a palette and still recolour three blocks to your own scheme.

= Blocks of your own

`custom` is the generic block: no meaning attached, every option available.

#ex("custom-basic", fig-width: 82%)

It takes bands and an activation band like a convolution does:

#ex("custom-bandfill", fig-width: 62%)

== Building a vocabulary

A `custom` layer with its options fixed is just a function returning a
dictionary, so your own block types are a few lines. This is the intended way to
draw something the package has no name for --- attention, a gate, a state-space
block --- rather than repurposing a type that means something else.

#ex-wide("custom-vocabulary", fig-width: 76%)

Give the constructor a `legend` and every block made from it shares one legend
entry.

= Connections

Arrows along the main axis are drawn for you. Anything else --- a skip, a
residual add, a lateral feed, an auxiliary path --- goes in `connections`, as a
list of routes between two named layers.

#ex("conn-basic", fig-width: 88%)

== Routing modes

`mode` picks where a route runs. `"air"` goes over the top and is the default,
`"flat"` underneath, `"depth"` along the projection's own axis.

#ex-wide("conn-modes", fig-width: 92%, fig-height: 7cm)

== Lane heights

`pos` is how far the route sits from the centre axis. It defaults to `auto`,
which ranks routes by how far they reach: a route spanning more blocks sits
higher, so a longer route always arcs over a shorter one instead of crossing it.

#ex("conn-pos", fig-width: 88%)

Routes of equal reach share a height. Where two of them overlap, the second goes
to the opposite side of the axis at the same height rather than being pushed
further out than its reach warrants. `lane-unit` on `draw-network` sets the
spacing between heights, and `clearance` on a route sets how far the lowest one
sits from the blocks.

A number overrides all of that for one route, measured from the axis:

#ex("conn-pos-manual", fig-width: 72%)

== Where a route arrives

By default a route arrives on the main axis just before its target. `touch-layer`
lands it on the target block itself, choosing a side from the routing mode: air
arrives on the top edge, flat on the bottom, depth on the left.

#ex-wide("conn-touch", fig-width: 88%)

Several routes landing on one block would stack their arrowheads on the same
point, so `arrive-offset` spreads them along whichever edge the mode chose. It
defaults to `auto`, which spaces a whole fan evenly and leaves a lone arrival
centred:

#ex-wide("conn-arrive-fan", fig-width: 88%, fig-height: 7cm)

Routes are grouped by the edge they land on, then spread across it: `k` routes
divide the edge into `k + 1` intervals and sit at the interior boundaries, so
the outermost pair is inset rather than sitting on the corners. They are ordered
by where each route starts, so a fan does not cross itself, and adding a route
respaces the rest.

#note[
  A route arriving on the bottom or left edge has its final stretch drawn behind
  the block, because those edges are on the far side and the route genuinely
  passes underneath before reaching them. Blocks are semi-transparent, so it
  shows faintly rather than disappearing.
]

== Telling routes apart

A residual add, a concat feed and an auxiliary supervision path are different
things, and by default they all look the same. `color`, `dash` and `thickness`
separate them:

#ex-wide("conn-style", fig-width: 88%)

`thickness` multiplies rather than replaces, so a figure that sets
`stroke-thickness` on `draw-network` still scales its routes. Arrowheads take
the line colour, since a coloured line with black arrowheads reads as a bug
rather than a choice.

Give a route a `legend` and it joins the legend as a line sample rather than a
colour swatch, since what distinguishes a route is its stroke and not a fill.
`main-legend` names the automatic axis arrows, which otherwise go unexplained:

#ex-wide("conn-legend", fig-width: 76%)

== Labelling a route

#ex-wide("conn-label", fig-width: 62%, fig-height: 4cm)

== Suppressing an axis arrow

`show-connection: false` removes the arrow *after* a layer. The input layer
defaults to `false`, which is why an image usually sits detached; set it `true`
to join it up.

#ex("conn-show-connection", fig-width: 88%)

= Groups and repeats

Backbone, neck and head are the phrases anyone uses out loud to explain one of
these figures. `groups` draws them, as labelled brackets under a span of layers.

#ex-wide("groups-basic", fig-width: 88%)

Each entry spans from one named layer to another, inclusive, and the two may be
the same layer. The bracket covers the drawn footprint rather than the front
faces, so it sits under the whole block including its lean, and its ends are
inset slightly so two adjacent groups read as two rather than as one continuous
rule.

Brackets are placed below everything else in the figure, including a route
running underneath the stack. `offset` pushes one further down, which is how you
stack a group enclosing other groups onto its own row, and `color` tints one:

#ex-wide("groups-stacked", fig-width: 88%, fig-height: 7cm)

== Repeated blocks

Depth-scaled models stack the same block several times. Writing that as extra
entries in `widths` makes it *look* repeated, but the package has no idea it is:
it cannot label the repeat or bracket it, and the figure claims one wide block
rather than several. `repeat` declares it:

#ex("repeat-basic", fig-width: 82%)

The block is drawn once, with a bracket above it carrying the count.

#note[
  Ghosted copies were tried first and rejected. An outline behind the block
  reads as an empty box rather than as another one of the same block, and
  drawing N of them is either misleading about the count or unreadable once N is
  large. A bracket states the count instead of depicting it, costs no horizontal
  space, and stays legible at any N.
]

`repeat` is ignored on `pool`, `unpool` and `sum`: the first two attach to the
block before them rather than being blocks in their own right, and a sum is a
node, not a stack. It also describes one layer entry and not a run of them, so a
repeated pair such as attention-then-MLP cannot be expressed with it.

= Parallel branches

`draw-network` advances one cursor along one axis, so anything genuinely
parallel --- two detection heads, the two paths inside a CSP block, a two-stream
fusion --- would have to be collapsed into a single block with arrows pointed at
it. A `branch` entry draws it as it is. Each branch is a layer list of its own.

#ex-wide("branch-basic", fig-width: 76%, fig-height: 7cm)

`spread` sets the separation, centred on the trunk, and `lead` how far the
fan-out and rejoin arrows run. An odd count puts one branch on the trunk line;
an even count leaves it empty. A filled dot marks each point where flow divides
or meets.

== Stacking along the projection

`spread-mode: "depth"` stacks the branches along the projection's 45-degree axis
instead of straight up, so they read as parallel copies sitting behind one
another. The fan-out and rejoin become two parallel spines with horizontal
teeth --- a parallelogram rather than the mirrored hexagon a vertical split
produces. Neither 45 is a free angle: it is the one the projection already uses.

#ex-wide("branch-depth", fig-width: 76%, fig-height: 7cm)

#note[
  `rejoin-lead` widens the rejoin side alone, which depth mode often wants,
  since its return spine descends past each block's lower-right corner --- which
  is exactly where diagonal dimension labels sit.
]

== Open at one end

A branch may be open at one end. `open: "start"` draws no fan-out, so the
branches simply begin. A branch with nothing before it is open at the start by
definition, which is how a multi-input network starts:

#ex-wide("branch-open-start", fig-width: 76%, fig-height: 7cm)

`open: "end"` draws no rejoin, so one trunk fans out into independent outputs:

#ex-wide("branch-open-end", fig-width: 76%, fig-height: 7cm)

== Nesting

A branch may contain branches, since walking a branch is the same operation as
walking the trunk.

#ex-wide("branch-nested", fig-width: 74%, fig-height: 8cm)

The rejoin waits for the longest branch rather than cutting the others short.
Named layers inside a branch join the same table the trunk uses, so connections,
groups and automatic lane ranking all reach into branches, and a group naming
any layer inside a branch widens to the branch's whole drawn extent, plumbing
included.

= The figure as a whole

== Legends

`show-legend: true` collects every layer type used into a legend, in order of
first appearance.

#ex("legend-basic", fig-width: 88%)

`legend` on a layer overrides the default name for its type, and `legend-title`
renames the whole box:

#ex("legend-names", fig-width: 88%)

Layers sharing a legend name appear once. Connection legend entries (chapter 10)
appear as line samples, and the sample column widens when any is present so a
dash pattern has room to read.

== Fitting the page

A figure is drawn at its natural size, which for a long network is wider than a
page. `scale` shrinks the whole thing, text included:

#ex("scale-fit", fig-width: 62%)

== Line weight and projection

`stroke-thickness` multiplies every stroke in the figure, which matters when a
figure is reduced for a two-column layout and hairlines start dropping out:

#ex("stroke-thickness", fig-width: 76%)

`depth-multiplier` controls how far blocks lean, which is the strength of the
isometric projection:

#ex("depth-multiplier", fig-width: 62%)

= Every option

The tables below are generated from the package itself rather than written out
here, so an option cannot exist without appearing in this chapter.

== Options by layer type

#layer-key-table()

== Connection options

#key-table(connection-keys, exclude: ())

== Group options

#key-table(group-keys, exclude: ())

== Arguments to draw-network

#snippet(```typ
#draw-network(
  layers,
  connections: (),
  groups: (),
  palette: "warm",
  show-legend: false,
  legend-title: "Layers",
  main-legend: none,
  scale: 100%,
  stroke-thickness: 1,
  depth-multiplier: 0.3,
  lane-unit: 0.75,
  shape-scale: (spatial: (1.2, -3.2), channels: (0.075, 0.0)),
  auto-gap: 0.55,
  show-relu: false,
)
```)

== Coverage

#undocumented((
  "name", "label", "legend", "offset", "shape", "repeat", "height", "depth",
  "channels", "fill", "opacity", "image", "show-connection", "connection-label",
  "label-orient", "label-dx", "label-dy", "label-anchor", "label-angle",
  "width", "widths", "bandfill", "show-relu", "input-style",
  "xlabel", "ylabel", "zlabel", "classes", "radius", "symbol", "stroke",
  "branches", "spread", "spread-mode", "lead", "rejoin-lead", "open",
  "from", "to", "mode", "pos", "clearance", "color", "dash", "thickness",
  "touch-layer", "arrive-offset", "layers",
))

= Where to go next

Complete architectures are in `examples/` in the repository, and their rendered
output in `gallery/`. They are ordinary Typst files, meant to be read and
copied:

#block(inset: (left: 6pt))[
  #set text(size: 9.5pt)
  / `examples/networks/`: AlexNet, LeNet-5, VGG16, VGG19, ResNet18, U-Net, FCN-8
    and YOLO26-n, plus five RGB-IR fusion variants of the last one and a figure
    opening up the fusion operators themselves.
  / `examples/features/`: the figures from this manual's ancestors, including
    every predefined layer type side by side in both palettes.
  / `examples/imported/`: figures generated from a traced PyTorch model rather
    than written by hand, using `tools/import_model.py`.
]

The YOLO26-n example is the one to read if you want to see the automatic
machinery carrying a whole figure: every block states its tensor shape, every
gap is automatic, every lane height is automatic, and the three detection heads
are a depth-mode branch. Nothing in it is sized or positioned by hand.

#!/usr/bin/env python3
"""Generate llms.txt, a single flat description of the package.

Most people will not read the manual. They will ask a model to write
neural-netz for them, and whether that works on the first try decides whether
they keep the package. So this file is written for that reader: no images, no
cross-references, no narrative, every option in one table, and a worked example
of every feature.

Both halves come from the package rather than from prose kept in step by hand.
The option tables are queried out of src/schema.typ, so an option cannot exist
without appearing here. The examples are the same files the manual compiles, so
an example here cannot be one that fails to compile.

    python3 doc/gen-llms.py > llms.txt
"""

import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
EXAMPLES = ROOT / "doc" / "examples"


def keys():
    out = subprocess.run(
        ["typst", "query", "--root", str(ROOT), str(ROOT / "doc" / "keys.typ"),
         "<neural-netz-keys>", "--field", "value", "--one"],
        capture_output=True, text=True, check=True,
    )
    return json.loads(out.stdout)


def example(name, title):
    """One example, as the code a user would actually write."""
    src = (EXAMPLES / f"{name}.typ").read_text()
    body = src.split("// @show\n", 1)[1].rstrip()
    return f"### {title}\n\n{body}\n"


HEADER = """# neural-netz

Neural network architecture diagrams for Typst, drawn as isometric block
diagrams in the style of PlotNeuralNet. Built on CeTZ.

You describe the network as an array of layers. The package computes geometry,
spacing, the arrows along the main axis, the routing of any skip connection, and
the legend.

## Import

    #import "@preview/neural-netz:0.4.0": draw-network, conv, pool, input

Version 0.4 is a fork and is not yet on Typst Universe, where `neural-netz`
still resolves to 0.3.0. Until it is published, import a local copy:

    #import "path/to/src/lib.typ": *

## Core model

A layer is a dictionary with a `type`, or equivalently a constructor call:

    (type: "conv", label: "a")     ==     conv(label: "a")

Prefer constructors: Typst rejects a misspelled argument by name, and the
signature lists the options that type accepts. Both forms work everywhere,
including inside `branches`, and mix freely.

Rules that are easy to get wrong:

- An option a layer type does not accept is an ERROR, not an ignored key. Check
  the per-type table below before using an option.
- `width` and `widths` are different options and not interchangeable. `widths`
  takes an array and draws one band per entry; only `conv`, `convres` and
  `custom` accept it. `input`, `deconv`, `concat`, `convsoftmax`, `softmax`,
  `output` and `custom` accept the scalar `width`. `pool`, `unpool`, `gap`, `fc`
  and `sum` accept neither.
- `channels` may have at most one more entry than the layer has bands. The extra
  entry becomes the diagonal axis label. More than that is an error from inside
  the package.
- Connections and groups refer to layers by `name`. A layer with no `name`
  cannot be referred to, and naming a layer that does not exist is an error.
- `offset`, `pos` and `arrive-offset` all default to `auto`. Do not write
  `offset: auto` or `pos: auto` explicitly; it is the default. Give a number
  only when overriding.
- `pool` and `unpool` attach to the layer before them unless given an `offset`.
- `sum` is a node with a `radius`, not a block with a width.
- `type: "skip"` is a CONNECTION type, not a layer type. There is no skip layer.

## draw-network arguments

    #draw-network(
      layers,                  // array of layer dictionaries; the only positional
      connections: (),         // array of route dictionaries
      groups: (),              // array of bracket dictionaries
      palette: "warm",         // "warm" or "cold"
      show-legend: false,
      legend-title: "Layers",
      main-legend: none,       // names the automatic axis arrows in the legend
      scale: 100%,             // shrinks the whole figure, text included
      stroke-thickness: 1,     // multiplies every stroke
      depth-multiplier: 0.3,   // strength of the isometric lean
      lane-unit: 0.75,         // spacing between automatic route heights
      shape-scale: (spatial: (1.2, -3.2), channels: (0.075, 0.0)),
      auto-gap: 0.55,          // white space added by automatic offsets
      show-relu: false,        // activation bands, figure-wide
    )

Also exported: `depth-shear(depth, depth-multiplier: 0.3)` and
`min-clear-offset(depth, depth-multiplier: 0.3)`, for figures computing their
own geometry.
"""

SEMANTICS = """## What each option means

Geometry:
- `height`, `depth` -- spatial extent of the tensor, in canvas units.
- `width` -- thickness of the block (scalar). Thickness conventionally means
  channel count.
- `widths` -- array of band thicknesses; draws several bands in one block.
- `shape: (channels, height, width)` -- derives height, depth and width from the
  tensor shape, logarithmically. Supplies DEFAULTS: anything stated explicitly
  wins, field by field. Only conv/convres/custom take a derived width.
- `offset` -- gap before this layer. Default `auto`: covers the previous block's
  isometric lean, adds `auto-gap`, and widens where a connection descends into
  the gap. A number overrides.
- `radius` -- sum node only, instead of a width.

Text:
- `label` -- name printed under the block.
- `channels` -- numbers along the top, one per band, plus at most one extra that
  becomes the diagonal axis label. Strings are allowed.
- `xlabel`, `ylabel`, `zlabel` -- axis names (conv, convres, custom only).
- `connection-label` -- label on the axis arrow AFTER this layer.
- `legend` -- overrides the default legend name for this layer's type.
- `label-orient` -- "horizontal" (default), "diagonal" or "vertical". Each
  preset pairs its angle with the correct anchor. Any other value is an error.
- `label-dx`, `label-dy`, `label-anchor`, `label-angle` -- manual placement.
  Setting both `label-orient` and `label-angle` is an error. Labels anchor on
  the baseline; use "base-east"/"base-west" for horizontal anchoring.

Appearance:
- `fill`, `opacity` -- block colour and solidity. Edge colours derive from fill.
- `bandfill` -- activation band colour (conv, convres, custom). Undeclared, it
  derives from the layer's own fill.
- `show-relu` -- per layer, overrides the figure-wide setting.
- `image` -- content drawn on the block's face, sheared to the projection. The
  string "default" uses the bundled photograph. Any content works, not only
  images.
- `stroke`, `symbol` -- sum node outline and symbol.
- `input-style` -- input/custom; draws the block as a flat plane.

Structure:
- `name` -- identifier for connections and groups. Not printed.
- `show-connection` -- draws the axis arrow AFTER this layer. Defaults true,
  except on `input`, where it defaults false.
- `repeat: N` -- marks the block as repeated in series, drawn once with a
  bracket carrying the count. Ignored on pool, unpool and sum. Describes one
  layer entry, not a run of them.
- `classes` -- softmax/output only.

## Connection options

A connection is a dictionary in the `connections` array.

- `from`, `to` -- REQUIRED, names of layers.
- `type` -- "skip" (default).
- `mode` -- "air" (over the top, default), "flat" (underneath), "depth" (along
  the projection).
- `pos` -- height from the centre axis. Default `auto`: routes are ranked by
  reach, so a longer route arcs over a shorter one. Equal reaches share a
  height; two overlapping equals split across the axis.
- `clearance` -- how far the lowest automatic route sits from the blocks.
- `touch-layer: true` -- arrive on the target block itself rather than on the
  axis arrow in front of it. The edge follows the mode: air lands on the top
  edge, flat on the bottom, depth on the left.
- `arrive-offset` -- position along that edge. Default `auto`: a fan spaces
  itself, a lone arrival stays centred.
- `color`, `dash`, `thickness` -- stroke. `thickness` MULTIPLIES the palette
  width, so it composes with `stroke-thickness`. Arrowheads take the line
  colour.
- `legend` -- adds a line-sample legend entry. Routes sharing a name appear once.
- `label` -- text on the route.
- `opacity`, `layers` -- rarely needed.

## Group options

A group is a labelled bracket under a span of layers.

- `from`, `to` -- REQUIRED, names of layers, inclusive. May be the same layer.
- `label` -- bracket text.
- `offset` -- pushes the bracket further down, for stacking rows of groups.
- `color` -- tints one bracket.

## Branches

`branch` draws genuinely parallel paths. It is a container: none of the block
options apply to it, only these.

- `branches` -- array of layer arrays, one per parallel path. REQUIRED.
- `spread` -- separation between paths, centred on the trunk. An odd count puts
  one path on the trunk line; an even count leaves it empty.
- `spread-mode` -- "vertical" (default) or "depth" (stacked along the
  projection's 45-degree axis).
- `lead` -- how far the fan-out and rejoin arrows run.
- `rejoin-lead` -- widens the rejoin side alone. Depth mode often wants this.
- `open` -- "start" draws no fan-out (a multi-input network), "end" draws no
  rejoin (independent outputs). A branch with nothing before it is open at the
  start by definition.

Branches nest. Named layers inside a branch join the same table the trunk uses,
so connections, groups and automatic lane ranking all reach into them. The
rejoin waits for the longest branch.
"""

ERRORS = """## Errors you will see

    neural-netz: unknown layer option "hieght" on layer 3 (type "conv").
    Did you mean "height"? Options accepted here: ...

The option does not exist for that type. Check the per-type table above; a
correctly spelled option that belongs to a different type gives this too.

    neural-netz: unknown layer type "convolution" on layer 0.

Use one of the fourteen types listed above.

    neural-netz: connection 0 refers to "bb", which is not the `name` of any
    layer. Did you mean "b"?

Add a `name` to the target layer, or fix the reference.

    neural-netz: layer 0 has no `type`.

Every layer dictionary states one. Constructors fill it in for you.

    error: array index out of bounds (index: 1, len: 1)  [inside src/lib.typ]

Almost always `channels` with more entries than the layer has bands, plus one.
Either add matching `widths` entries or remove channel entries.

    error: unexpected argument: lable

A constructor received an option that does not exist. This is Typst's own
message, raised before the package sees the call.

## Choosing a layer type

- `conv` -- convolution. Banded, thickness means channels.
- `convres` -- residual convolution. Same, different colour.
- `deconv` -- transposed convolution / upsampling.
- `pool` / `unpool` -- attach to the block before them; thin slabs.
- `fc` -- fully connected. Use `depth: 0` for a flat rectangle.
- `gap` -- global average pooling. Small by default.
- `concat` -- concatenation. A common target for a fan of `touch-layer` routes.
- `sum` -- element-wise sum. A disc, not a block.
- `softmax`, `convsoftmax` -- classifier heads.
- `output` -- terminal block.
- `input` -- flat plane, usually carrying an image. No outgoing arrow by default.
- `custom` -- everything else. Define your own block types as functions
  returning `custom(...)` with the options fixed.
- `branch` -- container for parallel paths.
"""


def main():
    k = keys()
    parts = [HEADER]

    parts.append("## Options accepted by each layer type\n")
    parts.append("Anything not listed for a type is an error on that type.\n")
    for ty in sorted(k["layers"]):
        opts = sorted(o for o in k["layers"][ty] if o != "type")
        parts.append(f"{ty}:\n  " + ", ".join(opts) + "\n")

    parts.append("\nConnection options:\n  " + ", ".join(sorted(k["connection"])) + "\n")
    parts.append("Group options:\n  " + ", ".join(sorted(k["group"])) + "\n")

    parts.append(SEMANTICS)

    parts.append("## Worked examples\n")
    parts.append("Every example below compiles as written, given the import above.\n")
    for name, title in EXAMPLE_ORDER:
        parts.append(example(name, title))

    parts.append(ERRORS)

    sys.stdout.write("\n".join(parts))


EXAMPLE_ORDER = [
    ("basics-minimal", "Minimal figure"),
    ("basics-dict", "Dictionary form"),
    ("basics-ctor", "Constructor form (equivalent)"),
    ("basics-mixed", "The two forms mix"),
    ("basics-named", "Names, connections and groups"),
    ("basics-shared", "Sharing options across layers"),
    ("basics-loop", "Generating layers"),
    ("types-overview", "The predefined types"),
    ("types-conv-family", "conv, convres and custom"),
    ("types-pool-attached", "Pooling attaches to the block before it"),
    ("types-pool-detached", "An offset detaches a pool"),
    ("types-pool-unpool", "Pool down, unpool up"),
    ("types-sum-variants", "Sum nodes"),
    ("types-gap-concat", "Global pooling and concatenation"),
    ("types-heads", "Classifier heads"),
    ("types-input-plane", "The input layer"),
    ("types-classifier", "A classifier from types alone"),
    ("size-height", "height"),
    ("size-depth", "depth"),
    ("size-width", "Thickness"),
    ("size-widths-count", "Several bands in one block"),
    ("size-widths-uneven", "Uneven bands (a bottleneck)"),
    ("size-2d", "A flat layer"),
    ("size-shape-basic", "Sizing from a tensor shape"),
    ("size-shape-pyramid", "A shape pyramid"),
    ("size-shape-override", "Shape supplies defaults, not values"),
    ("size-shape-scale", "Changing the shape mapping"),
    ("spacing-default", "Automatic spacing (the default)"),
    ("spacing-tight-bad", "WRONG: a constant offset narrower than the lean"),
    ("spacing-tight-good", "RIGHT: the same blocks spaced automatically"),
    ("spacing-numbers", "Spacing by hand"),
    ("spacing-conn-widens", "A gap widening for a descending route"),
    ("spacing-gap-wide", "auto-gap"),
    ("label-basic", "Labels"),
    ("label-multiline", "Multi-line labels"),
    ("label-channels-bands", "Channel numbers, one per band"),
    ("label-channels-axis", "The extra entry is the axis label"),
    ("label-channels-strings", "Strings as channel labels"),
    ("label-axes", "Axis names"),
    ("label-connection", "Labelling the arrow between blocks"),
    ("label-crowded-bad", "WRONG: labels colliding"),
    ("label-crowded-orient", "RIGHT: rotate them"),
    ("label-crowded-stagger", "RIGHT: or stagger one"),
    ("label-anchor-fan", "Or fan them by anchor"),
    ("label-orient-compare", "The three orientation presets"),
    ("label-angle-free", "An arbitrary angle"),
    ("image-input-default", "An image on the input"),
    ("image-input-custom", "Your own image"),
    ("image-on-block", "An image on a later block"),
    ("image-content-symbol", "A symbol on a block"),
    ("image-content-text", "Arbitrary content on a block"),
    ("color-fill-compare", "Recolouring"),
    ("color-opacity-compare", "Opacity"),
    ("color-relu-on", "Activation bands"),
    ("color-bandfill", "Band colour"),
    ("palette-cold", "The cold palette"),
    ("color-brand", "A figure on your own scheme"),
    ("custom-basic", "Custom blocks"),
    ("custom-bands", "A banded custom block"),
    ("custom-legend", "Legend names on custom blocks"),
    ("custom-vocabulary", "Defining your own block types"),
    ("custom-transformer", "A figure written in that vocabulary"),
    ("conn-basic", "A skip connection"),
    ("conn-mode-air", "mode: air"),
    ("conn-mode-flat", "mode: flat"),
    ("conn-mode-depth", "mode: depth"),
    ("conn-lanes-auto", "Automatic lane heights"),
    ("conn-lanes-overlap", "Equal reach, overlapping"),
    ("conn-lanes-manual", "A stated height"),
    ("conn-lane-unit", "lane-unit"),
    ("conn-touch-compare", "Arriving on the block itself"),
    ("conn-touch-modes", "All three arrival edges"),
    ("conn-arrive-auto", "A fan of arrivals, spaced automatically"),
    ("conn-arrive-manual", "Placing arrivals by hand"),
    ("conn-style-compare", "Telling routes apart"),
    ("conn-legend", "Routes in the legend"),
    ("conn-label", "Labelling a route"),
    ("conn-noarrow", "Suppressing an axis arrow"),
    ("conn-input-arrow", "Joining the input up"),
    ("conn-residual-block", "COMPOSITE: a residual block"),
    ("conn-unet-skips", "COMPOSITE: encoder-decoder skips"),
    ("groups-basic", "Group brackets"),
    ("groups-single", "A group of one layer"),
    ("groups-color", "Tinting brackets"),
    ("groups-stacked", "Stacked group rows"),
    ("groups-clear-routes", "Brackets clear routes automatically"),
    ("repeat-basic", "Repeated blocks"),
    ("repeat-counts", "Any count"),
    ("repeat-pool-bad", "WRONG: repeat on a conv with a pool attached"),
    ("repeat-pool-good", "RIGHT: split the repeat off"),
    ("groups-composite", "COMPOSITE: backbone, neck, head"),
    ("branch-two", "Parallel branches"),
    ("branch-three", "An odd count sits on the trunk line"),
    ("branch-uneven", "Branches of different lengths"),
    ("branch-spread", "spread and lead"),
    ("branch-depth", "Stacked along the projection"),
    ("branch-depth-three", "Three heads in depth mode"),
    ("branch-open-start", "A multi-input network"),
    ("branch-open-end", "Independent outputs"),
    ("branch-nested", "Nested branches"),
    ("branch-connections", "Connections and groups reach into branches"),
    ("branch-two-stream", "COMPOSITE: two-stream fusion"),
    ("branch-inception", "COMPOSITE: an inception block"),
    ("legend-basic", "A legend"),
    ("legend-names", "Renaming legend entries"),
    ("legend-mixed", "Layers and routes in one legend"),
    ("scale-55", "Fitting the page"),
    ("stroke-thick", "Line weight"),
    ("depth-strong", "Projection strength"),
    ("recipe-classifier", "PATTERN: a classifier"),
    ("recipe-encoder-decoder", "PATTERN: an encoder-decoder"),
    ("recipe-residual-stage", "PATTERN: residual stages"),
    ("recipe-multiscale", "PATTERN: a multi-scale head"),
    ("recipe-programmatic", "PATTERN: a repeated pair, built with a loop"),
]


if __name__ == "__main__":
    main()

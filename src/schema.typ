// Option tables, input validation and layer constructors.
//
// A dictionary API has one characteristic failure: a key the drawing code does
// not read is silently ignored. `hieght: 4` does not fail, it draws a figure
// that is merely wrong, so the package looks broken rather than the typo
// looking like a typo. The tables below say which options each layer type
// actually understands, `check-layers` turns anything else into an error, and
// the constructors at the bottom are built from the same tables so the two
// cannot disagree about what `conv` accepts.

// Options every drawn layer understands. `sum` and `branch` are not drawn as
// prisms and have their own sets, further down.
#let layer-common-keys = (
  "type", "name", "label", "legend", "offset", "shape", "repeat",
  "height", "depth", "channels", "fill", "opacity", "image",
  "show-connection", "connection-label",
  "label-orient", "label-dx", "label-dy", "label-anchor", "label-angle",
)

// What each type adds. A block's thickness means channel count only for the
// three types that take `widths`; the rest have a fixed thickness that says
// something else, which is why `width` is not universal.
#let layer-extra-keys = (
  input: ("width", "input-style"),
  conv: ("widths", "bandfill", "show-relu", "xlabel", "ylabel", "zlabel"),
  convres: ("widths", "bandfill", "show-relu", "xlabel", "ylabel", "zlabel"),
  custom: ("width", "widths", "bandfill", "show-relu", "input-style",
           "xlabel", "ylabel", "zlabel"),
  deconv: ("width",),
  concat: ("width",),
  convsoftmax: ("width",),
  softmax: ("width", "classes"),
  output: ("width", "classes"),
  pool: (),
  unpool: (),
  gap: (),
  fc: (),
)

#let layer-keys = {
  let m = (:)
  for (ty, extra) in layer-extra-keys { m.insert(ty, layer-common-keys + extra) }
  // A node rather than a block: it has a radius and a symbol instead of a
  // width, a depth that only affects how far routes clear it, and no shape.
  m.insert("sum", (
    "type", "name", "label", "legend", "offset", "height", "depth", "channels",
    "fill", "opacity", "radius", "symbol", "stroke",
    "show-connection", "connection-label",
    "label-orient", "label-dx", "label-dy", "label-anchor", "label-angle",
  ))
  // A container: it draws no block of its own, so none of the block options
  // apply to it. They apply to the layers inside its branches.
  m.insert("branch", (
    "type", "name", "branches", "spread", "spread-mode", "lead", "rejoin-lead", "open",
  ))
  m
}

#let connection-keys = (
  "from", "to", "type", "mode", "pos", "label", "opacity", "color", "dash",
  "thickness", "legend", "touch-layer", "arrive-offset", "clearance", "layers",
)

#let group-keys = ("from", "to", "label", "offset", "color")

// Levenshtein distance, so an unknown key can be reported alongside the key it
// was probably meant to be. Two short strings, so the quadratic fill is fine.
#let edit-distance(a, b) = {
  let a = a.clusters()
  let b = b.clusters()
  let prev = range(b.len() + 1)
  for i in range(1, a.len() + 1) {
    let cur = (i,)
    for j in range(1, b.len() + 1) {
      let cost = if a.at(i - 1) == b.at(j - 1) { 0 } else { 1 }
      cur.push(calc.min(cur.at(j - 1) + 1, prev.at(j) + 1, prev.at(j - 1) + cost))
    }
    prev = cur
  }
  prev.last()
}

// The nearest candidate, when it is near enough to be worth naming. The
// threshold grows with the key's length so that a long name tolerates two
// slips while a three-letter one does not get matched to something unrelated.
#let did-you-mean(key, candidates) = {
  if type(key) != str { return "" }
  let best = none
  let best-d = 0
  for k in candidates {
    let d = edit-distance(key, k)
    if best == none or d < best-d { best = k; best-d = d }
  }
  if best != none and best-d <= calc.max(2, int(key.len() / 3)) {
    " Did you mean \"" + best + "\"?"
  } else { "" }
}

#let check-keys(what, where, dict, allowed) = {
  for k in dict.keys() {
    if k not in allowed {
      panic(
        "neural-netz: unknown " + what + " option \"" + k + "\" " + where + "."
          + did-you-mean(k, allowed)
          + " Options accepted here: " + allowed.sorted().join(", ") + "."
      )
    }
  }
}

#let check-layer(l, where) = {
  if type(l) != dictionary {
    panic(
      "neural-netz: " + where + " must be a dictionary such as (type: \"conv\", ...) "
        + "or a constructor call such as conv(...); got " + repr(l) + "."
    )
  }
  if "type" not in l {
    panic(
      "neural-netz: " + where + " has no `type`. Every layer states one, "
        + "for example (type: \"conv\", ...). Known types: "
        + layer-keys.keys().sorted().join(", ") + "."
    )
  }
  let ty = l.at("type")
  if type(ty) != str or ty not in layer-keys {
    panic(
      "neural-netz: unknown layer type " + repr(ty) + " on " + where + "."
        + did-you-mean(ty, layer-keys.keys())
        + " Known types: " + layer-keys.keys().sorted().join(", ") + "."
    )
  }
  check-keys("layer", "on " + where + " (type \"" + ty + "\")", l, layer-keys.at(ty))
}

// Every name declared anywhere in the layer tree, branches included, so that a
// connection or group naming a layer that does not exist is an error rather
// than a route that quietly fails to be drawn.
#let collect-names(layers) = {
  let names = ()
  for l in layers {
    if type(l) != dictionary { continue }
    let n = l.at("name", default: none)
    if n != none { names.push(n) }
    if l.at("type", default: none) == "branch" {
      for sub in l.at("branches", default: ()) {
        if type(sub) == array { names += collect-names(sub) }
      }
    }
  }
  names
}

#let check-layers(layers, where) = {
  if type(layers) != array {
    panic("neural-netz: " + where + " must be an array of layers; got " + repr(layers) + ".")
  }
  for (i, l) in layers.enumerate() {
    let w = where + " " + str(i)
    check-layer(l, w)
    if l.at("type") == "branch" {
      let subs = l.at("branches", default: ())
      if type(subs) != array {
        panic(
          "neural-netz: `branches` on " + w + " must be an array of layer arrays, "
            + "one per parallel path; got " + repr(subs) + "."
        )
      }
      for (j, sub) in subs.enumerate() {
        check-layers(sub, w + ", branch " + str(j) + ", layer")
      }
    }
  }
}

#let check-connections(connections, names) = {
  if type(connections) != array {
    panic("neural-netz: `connections` must be an array; got " + repr(connections) + ".")
  }
  for (i, c) in connections.enumerate() {
    if type(c) != dictionary {
      panic("neural-netz: connection " + str(i) + " must be a dictionary; got " + repr(c) + ".")
    }
    for k in ("from", "to") {
      if k not in c {
        panic(
          "neural-netz: connection " + str(i) + " has no `" + k + "`. A connection "
            + "names the two layers it runs between, so both layers need a `name`."
        )
      }
    }
    let where = "on connection " + str(i) + " (" + repr(c.at("from")) + " -> " + repr(c.at("to")) + ")"
    check-keys("connection", where, c, connection-keys)
    for k in ("from", "to") {
      if c.at(k) not in names {
        panic(
          "neural-netz: connection " + str(i) + " refers to " + repr(c.at(k))
            + ", which is not the `name` of any layer." + did-you-mean(c.at(k), names)
        )
      }
    }
  }
}

#let check-groups(groups, names) = {
  if type(groups) != array {
    panic("neural-netz: `groups` must be an array; got " + repr(groups) + ".")
  }
  for (i, g) in groups.enumerate() {
    if type(g) != dictionary {
      panic("neural-netz: group " + str(i) + " must be a dictionary; got " + repr(g) + ".")
    }
    for k in ("from", "to") {
      if k not in g {
        panic(
          "neural-netz: group " + str(i) + " has no `" + k + "`. A group spans from "
            + "one named layer to another, inclusive, and the two may be the same."
        )
      }
    }
    check-keys("group", "on group " + str(i), g, group-keys)
    for k in ("from", "to") {
      if g.at(k) not in names {
        panic(
          "neural-netz: group " + str(i) + " refers to " + repr(g.at(k))
            + ", which is not the `name` of any layer." + did-you-mean(g.at(k), names)
        )
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Constructors
//
// `conv(shape: (64, 160, 160), label: "P2")` rather than
// `(type: "conv", shape: (64, 160, 160), label: "P2")`. The dictionary form
// still works everywhere and is validated identically; the constructors exist
// because a named parameter is checked by Typst before this package sees it,
// and because the signature of each one is the list of options that type
// accepts, which is a reference an editor can show you while you type.
//
// A layer distinguishes an absent option from one set to `none`: an absent
// `bandfill` derives a band colour from the layer's fill, and an absent
// `offset` on a pool attaches it to the block in front of it. So the
// constructors default every parameter to a private sentinel and drop the ones
// still holding it, rather than passing `none` through.

#let unset = (neural-netz-unset: true)

#let mk(ty, args) = {
  let l = (type: ty)
  for (k, v) in args { if v != unset { l.insert(k, v) } }
  check-layer(l, "this " + ty + " layer")
  l
}

#let input(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  width: unset, height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset, input-style: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("input", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  width: width, height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image, input-style: input-style,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let conv(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  widths: unset, height: unset, depth: unset, channels: unset,
  fill: unset, bandfill: unset, opacity: unset, image: unset, show-relu: unset,
  show-connection: unset, connection-label: unset,
  xlabel: unset, ylabel: unset, zlabel: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("conv", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  widths: widths, height: height, depth: depth, channels: channels,
  fill: fill, bandfill: bandfill, opacity: opacity, image: image, show-relu: show-relu,
  show-connection: show-connection, connection-label: connection-label,
  xlabel: xlabel, ylabel: ylabel, zlabel: zlabel,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let convres(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  widths: unset, height: unset, depth: unset, channels: unset,
  fill: unset, bandfill: unset, opacity: unset, image: unset, show-relu: unset,
  show-connection: unset, connection-label: unset,
  xlabel: unset, ylabel: unset, zlabel: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("convres", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  widths: widths, height: height, depth: depth, channels: channels,
  fill: fill, bandfill: bandfill, opacity: opacity, image: image, show-relu: show-relu,
  show-connection: show-connection, connection-label: connection-label,
  xlabel: xlabel, ylabel: ylabel, zlabel: zlabel,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let deconv(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  width: unset, height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("deconv", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  width: width, height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let pool(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("pool", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let unpool(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("unpool", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let concat(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  width: unset, height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("concat", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  width: width, height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let gap(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("gap", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let fc(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("fc", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let softmax(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  width: unset, height: unset, depth: unset, channels: unset, classes: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("softmax", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  width: width, height: height, depth: depth, channels: channels, classes: classes,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let convsoftmax(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  width: unset, height: unset, depth: unset, channels: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("convsoftmax", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  width: width, height: height, depth: depth, channels: channels,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let output(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  width: unset, height: unset, depth: unset, channels: unset, classes: unset,
  fill: unset, opacity: unset, image: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("output", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  width: width, height: height, depth: depth, channels: channels, classes: classes,
  fill: fill, opacity: opacity, image: image,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let custom(
  name: unset, label: unset, legend: unset, offset: unset, shape: unset, repeat: unset,
  width: unset, widths: unset, height: unset, depth: unset, channels: unset,
  fill: unset, bandfill: unset, opacity: unset, image: unset, show-relu: unset,
  input-style: unset, show-connection: unset, connection-label: unset,
  xlabel: unset, ylabel: unset, zlabel: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("custom", (
  name: name, label: label, legend: legend, offset: offset, shape: shape, repeat: repeat,
  width: width, widths: widths, height: height, depth: depth, channels: channels,
  fill: fill, bandfill: bandfill, opacity: opacity, image: image, show-relu: show-relu,
  input-style: input-style, show-connection: show-connection, connection-label: connection-label,
  xlabel: xlabel, ylabel: ylabel, zlabel: zlabel,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

#let sum(
  name: unset, label: unset, legend: unset, offset: unset,
  height: unset, depth: unset, channels: unset,
  radius: unset, symbol: unset, fill: unset, stroke: unset, opacity: unset,
  show-connection: unset, connection-label: unset,
  label-orient: unset, label-dx: unset, label-dy: unset, label-anchor: unset, label-angle: unset,
) = mk("sum", (
  name: name, label: label, legend: legend, offset: offset,
  height: height, depth: depth, channels: channels,
  radius: radius, symbol: symbol, fill: fill, stroke: stroke, opacity: opacity,
  show-connection: show-connection, connection-label: connection-label,
  label-orient: label-orient, label-dx: label-dx, label-dy: label-dy,
  label-anchor: label-anchor, label-angle: label-angle,
))

// `branches` is an array of layer arrays, one per parallel path.
#let branch(
  branches: (),
  name: unset, spread: unset, spread-mode: unset,
  lead: unset, rejoin-lead: unset, open: unset,
) = mk("branch", (
  branches: branches, name: name, spread: spread, spread-mode: spread-mode,
  lead: lead, rejoin-lead: rejoin-lead, open: open,
))

// Connections and groups get the same treatment, for the same reason: a
// misspelled `colour` on a connection is otherwise a route that comes out the
// default colour with nothing to say why.
#let connection(
  from: unset, to: unset, type: unset, mode: unset, pos: unset, clearance: unset,
  label: unset, legend: unset, color: unset, dash: unset, thickness: unset,
  opacity: unset, touch-layer: unset, arrive-offset: unset, layers: unset,
) = {
  let c = (:)
  for (k, v) in (
    from: from, to: to, type: type, mode: mode, pos: pos, clearance: clearance,
    label: label, legend: legend, color: color, dash: dash, thickness: thickness,
    opacity: opacity, touch-layer: touch-layer, arrive-offset: arrive-offset, layers: layers,
  ) { if v != unset { c.insert(k, v) } }
  for k in ("from", "to") {
    if k not in c { panic("neural-netz: connection(..) needs `" + k + "`, the name of a layer.") }
  }
  c
}

#let group(from: unset, to: unset, label: unset, offset: unset, color: unset) = {
  let g = (:)
  for (k, v) in (from: from, to: to, label: label, offset: offset, color: color) {
    if v != unset { g.insert(k, v) }
  }
  for k in ("from", "to") {
    if k not in g { panic("neural-netz: group(..) needs `" + k + "`, the name of a layer.") }
  }
  g
}

// Presentation helpers for the manual.
//
// Every figure in this document is a standalone Typst file under doc/examples/,
// compiled to its own PDF by doc/build.sh and included here. Nothing is drawn
// inline. So each example can be opened, compiled and edited on its own, the
// manual stays quick to typeset, and a figure that fails to compile fails the
// build rather than quietly going missing.
//
// The same file supplies the code listing, read back from disk, so the listing
// and the picture cannot disagree. An example file carries a preamble the
// reader does not need to see on every page; everything after the `// @show`
// marker is what gets printed.

#import "../src/schema.typ": layer-keys, connection-keys, group-keys

// House palette.
#let garnet = rgb("#73000A")
#let rose = rgb("#CC2E40")
#let atlantic = rgb("#466A9F")
#let congaree = rgb("#1F414D")
#let warm-grey = rgb("#676156")
#let sandstorm = rgb("#FFF2E3")
#let grey-10 = rgb("#ECECEC")
#let grey-30 = rgb("#C7C7C7")
#let grey-50 = rgb("#A2A2A2")
#let grey-70 = rgb("#5C5C5C")
#let grey-90 = rgb("#363636")

#let ex-dir = "examples/"
#let build-dir = "build/"

// The part of an example worth printing: everything after the marker, or the
// whole file when it carries no preamble.
#let ex-source(name) = {
  let src = read(ex-dir + name + ".typ")
  let marker = "// @show\n"
  let body = if src.contains(marker) { src.split(marker).slice(1).join(marker) } else { src }
  body.trim(at: end)
}

#let code-block(body) = block(
  fill: sandstorm,
  stroke: (left: 1.5pt + garnet, rest: 0.5pt + grey-30),
  inset: (x: 7pt, y: 6pt),
  width: 100%,
  radius: 0pt,
  text(size: 8pt, raw(body, lang: "typ", block: true)),
)

// A figure is drawn at whatever size its own canvas came out, which for a tall
// or long network is most of a page. Constraining both axes and letting the
// image fit inside keeps every example the same visual weight, so a page is
// laid out by what the examples say rather than by how big they happened to be.
#let figure-block(name, width, height) = block(
  stroke: 0.5pt + grey-30,
  inset: 6pt,
  width: 100%,
  radius: 0pt,
  align(center, image(build-dir + name + ".pdf", width: width, height: height, fit: "contain")),
)

// Code on the left, picture on the right. The default for a small example.
#let ex(name, ratio: 1fr, fig-width: 100%, fig-height: 4.2cm, caption: none) = {
  block(breakable: false, width: 100%, {
    grid(
      columns: (1fr, ratio),
      column-gutter: 8pt,
      align: horizon,
      code-block(ex-source(name)),
      figure-block(name, fig-width, fig-height),
    )
    if caption != none {
      v(3pt)
      text(size: 8pt, fill: grey-70, style: "italic", caption)
    }
  })
}

// Code above, picture below, full width. For anything too wide to sit beside
// its own source.
#let ex-wide(name, fig-width: 100%, fig-height: 6cm, caption: none) = {
  block(breakable: false, width: 100%, {
    code-block(ex-source(name))
    v(4pt)
    figure-block(name, fig-width, fig-height)
    if caption != none {
      v(3pt)
      text(size: 8pt, fill: grey-70, style: "italic", caption)
    }
  })
}

// A picture with no listing, for the odd figure whose source says nothing.
#let ex-figure(name, fig-width: 100%, fig-height: 6cm, caption: none) = {
  block(breakable: false, width: 100%, {
    figure-block(name, fig-width, fig-height)
    if caption != none {
      v(3pt)
      align(center, text(size: 8pt, fill: grey-70, style: "italic", caption))
    }
  })
}

// A listing with no picture, for a fragment that is not a whole figure.
#let snippet(body) = code-block(body.text.trim(at: end))

// One option's reference entry, in the style of a key description.
#let opt(name, default: none, applies: none, body) = {
  block(breakable: false, width: 100%, above: 9pt, below: 7pt, {
    grid(
      columns: (auto, 1fr),
      column-gutter: 6pt,
      text(font: "DejaVu Sans Mono", size: 9pt, weight: "bold", fill: garnet, name),
      if default != none {
        align(right, text(size: 8pt, fill: grey-70)[default #raw(default)])
      } else { [] },
    )
    if applies != none {
      v(1pt)
      text(size: 7.5pt, fill: grey-70, style: "italic", applies)
    }
    v(2pt)
    pad(left: 10pt, body)
  })
}

#let note(body) = block(
  fill: grey-10,
  stroke: (left: 1.5pt + atlantic, rest: none),
  inset: (x: 8pt, y: 6pt),
  width: 100%,
  radius: 0pt,
  text(size: 9pt, body),
)

#let warn(body) = block(
  fill: rgb("#FBEAEC"),
  stroke: (left: 1.5pt + rose, rest: none),
  inset: (x: 8pt, y: 6pt),
  width: 100%,
  radius: 0pt,
  text(size: 9pt, body),
)

// Reference tables, built from src/schema.typ rather than restated here, so an
// option added to the package cannot go missing from its own manual.
#let key-table(keys, exclude: ("type",)) = {
  let ks = keys.filter(k => k not in exclude).sorted()
  block(width: 100%, text(size: 8.5pt, font: "DejaVu Sans Mono", ks.join(sym.space.en + sym.dot.c + sym.space.en)))
}

#let layer-key-table() = {
  let types = layer-keys.keys().sorted()
  table(
    columns: (auto, 1fr),
    stroke: 0.4pt + grey-50,
    inset: (x: 5pt, y: 4pt),
    align: (left + top, left + top),
    table.header(
      text(weight: "bold", size: 9pt)[Type],
      text(weight: "bold", size: 9pt)[Options],
    ),
    ..types.map(t => (
      text(font: "DejaVu Sans Mono", size: 8.5pt, weight: "bold", fill: garnet, t),
      text(font: "DejaVu Sans Mono", size: 7.5pt,
        layer-keys.at(t).filter(k => k != "type").sorted().join(", ")),
    )).flatten()
  )
}

// The document's own consistency check: an option present in the package but
// never mentioned in the prose is a documentation bug, and this is what makes
// it visible rather than something a reader discovers by its absence.
#let undocumented(documented) = {
  let all = ()
  for (_, ks) in layer-keys { all += ks }
  all += connection-keys
  all += group-keys
  let missing = all.dedup().filter(k => k != "type" and k not in documented).sorted()
  if missing.len() == 0 {
    note[Every option exported by the package is described somewhere above.]
  } else {
    warn[
      Not described anywhere in this manual:
      #text(font: "DejaVu Sans Mono", size: 8.5pt, missing.join(", ")).
    ]
  }
}

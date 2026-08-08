#import "@preview/cetz:0.4.2": canvas, draw

// How far a layer's top and side faces lean to the right, in canvas units.
//
// Layers are drawn in isometric projection: a layer of the given depth shears
// its far face right by this amount. The number matters when placing a
// connection, because the *visual* gap between two adjacent layers is not the
// `offset` between them but `offset - depth-shear(depth)`. A connection routed
// into what looks like empty space between two layers will cross the previous
// layer's sheared top face whenever that gap is too narrow.
//
// `depth-multiplier` must match the value passed to `draw-network`.
#let depth-shear(depth, depth-multiplier: 0.3) = depth * depth-multiplier

// The smallest `offset` that leaves a connection room to descend between two
// adjacent layers without crossing the first one's sheared faces.
//
// A connection descending into the gap arrives at the midpoint of the arrow
// joining the two layers, so it clears the shear only when half the offset
// exceeds it: offset > 2 * depth-shear(depth).
#let min-clear-offset(depth, depth-multiplier: 0.3) = 2 * depth-shear(depth, depth-multiplier: depth-multiplier)

// Draw a neural network from layer specifications
#let draw-network(
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
) = {


let colors-warm = (
  conv: rgb("#ffe0a1"),
  conv-relu: rgb("#ffa947"),  
  pool: rgb("#e04227"),
  unpool: rgb("#2E7D7D"),
  deconv: rgb("#88C1D0"),
  concat: rgb("#B39DDB"),
  softmax: rgb("#6A0066"),
  gap: rgb("#FF69B4"),
  fc: rgb("#B39DDB"),
  fc-relu: rgb("#9575CD"),
  sum: rgb("#FFFFFF"),
  sum-stroke: rgb("#000000"),
  convres: rgb("#e681a8"),
  convres-relu: rgb("#ad507e"),
  convsoftmax: rgb("#6A0066"),
  input: rgb("#f7f1ed"),
  output: rgb("#6A0066"),
  custom: rgb("#dad9d7"),
  custom-relu: rgb("#a8a7a4"),
  arrow: rgb("#000000"),
  connection: rgb("#000000"),
)

// Cold palette
let colors-cold = (
  conv: rgb("#CDEDFE"),
  conv-relu: rgb("#89C7E8"),
  pool: rgb("#af78e6"),
  unpool: rgb("#B8A3E8"),
  deconv: rgb("#96e7c8"),
  concat: rgb("#7EC8E3"),
  softmax: rgb("#4A148C"),
  gap: rgb("#E91E63"),
  fc: rgb("#9FA8DA"),
  fc-relu: rgb("#7986CB"),
  sum: rgb("#FFFFFF"),
  sum-stroke: rgb("#000000"),
  convres: rgb("#8edbd5"),
  convres-relu: rgb("#54adac"),
  convsoftmax: rgb("#4A148C"),
  input: rgb("#ecebf5"),
  output: rgb("#4A148C"),
  custom: rgb("#d7d9da"),
  custom-relu: rgb("#a1a4ad"),
  arrow: rgb("#000000"),
  connection: rgb("#000000"),
)

let strokes = (
  solid: (paint: black.lighten(20%), thickness: 0.65pt * stroke-thickness),
  hidden: (paint: gray.darken(50%).transparentize(50%), thickness: 0.45pt * stroke-thickness, dash: (1pt, 0.8pt)),
  arrow: (thickness: 0pt),
  connection: (thickness: 1pt * stroke-thickness),
)

let dynamic-color-strokes(fill) = {
  (
    solid: (paint: fill.darken(50%).saturate(80%), thickness: strokes.solid.thickness),
    hidden: (paint: fill.darken(60%).saturate(80%).transparentize(60%), thickness: strokes.hidden.thickness, dash: strokes.hidden.dash),
  )
}

let font-sizes = (
  label: 8.5pt,
  channel-number: 7pt,
  layer-label: 8.5pt,
  output-number: 8pt,
  legend-title: 10pt,
  legend-item: 8pt,
)

let opacity-values = (
  front-face: 30%,
  top-face: 30%,
  right-face: 30%,
  band: 60%,
  ball: 10%,
  edge: 70%,
)

let darken-amounts = (
  top: 0%,
  right: 0%,
)

let arrow-config = (
  triangle-size: 0.2,
  axis-y: 2.5
)

let depth-angle-deg = 45deg //calc.atan(depth-multiplier) * 180 / calc.pi

let get-depth-offsets(d) = {
  let s = depth-shear(d, depth-multiplier: depth-multiplier)
  (s, s)
}

let get-y-offset-for-center-on-axis(h, d, axis-y) = {
  let (_, oy) = get-depth-offsets(d)
  axis-y - h / 2 - oy / 2
}

let get-perspective-center-y(y-offset, h, oy) = {
  y-offset + h / 2 + oy / 2
}

let get-layer-anchors(x, y, w, h, ox, oy) = {
  let center-x = x + w/2 + ox/2
  let center-y = y + h/2 + oy/2
  (
    west: (x, center-y),
    east: (x + w + ox, center-y),
    // True west/east are the geometric centers of the 3D west/east faces
    // West face center: halfway through depth, centered vertically
    true_west: (x + ox/2, center-y),
    // East face center: at right edge minus half depth, centered vertically  
    true_east: (x + w + ox/2, center-y),
    north: (center-x, y + h + oy),
    south: (center-x, y),
    anchor: (center-x, center-y),
    near: (center-x, center-y),
    northeast: (x + w + ox, y + h + oy),
    southeast: (x + w + ox, y),
    northwest: (x, y + h + oy),
    southwest: (x, y),
  )
}

let coord-along-path(start, end, pos: 1.0) = {
  (start.at(0) + (end.at(0) - start.at(0)) * pos,
   start.at(1) + (end.at(1) - start.at(1)) * pos)
}

let get-circle-boundary-point(from-pt, center-pt, radius) = {
  let dx = center-pt.at(0) - from-pt.at(0)
  let dy = center-pt.at(1) - from-pt.at(1)
  let dist = calc.sqrt(dx * dx + dy * dy)
  if dist > 0 {
    let ux = dx / dist
    let uy = dy / dist
    (center-pt.at(0) - ux * radius, center-pt.at(1) - uy * radius)
  } else {
    (center-pt.at(0) + radius, center-pt.at(1))
  }
}

let colors = if palette == "cold" { colors-cold } else { colors-warm }
let scale-factor = scale / 100%


canvas(length: 1cm * scale-factor, {
  import draw: *
  
  let scaled-font = (size) => size * scale-factor
  
  // Helper function: Draw isometric image on right face
  let draw-isometric-image(x, y, w, h, ox, oy, image) = {
    let img-height = (h) * 28.25pt * scale-factor
    let img-width = (oy / depth-multiplier) * 28.25pt * scale-factor

    let actual-img-width() = measure(image).width
    let actual-img-height() = measure(image).height

    content((x+w+ox/2,y+h/2+oy/2),
      context {
        pad(
          x: -((1+depth-multiplier) * img-height - img-width)/2,
          y: +(img-height/2 - img-width)/2
        )[ 
        #std.rotate(90deg)[
        #std.skew(ax: 45deg)[ 
        #std.rotate(-90deg)[
        #pad(
          x: -(actual-img-width() - img-width * depth-multiplier)/2,
          y: -(actual-img-height() - img-height)/2
        )[ 
        #std.scale(x: img-width * depth-multiplier, y: img-height)[ 
        #image]
        ]]]]]
      }
    )
  }
  
  // Outline a prism as one closed silhouette + its 3 near-corner creases (round joins).
  let draw-prism-silhouette(px, py, pw, ph, pox, poy, base, show-right: true) = {
    let s = (paint: base.paint, thickness: base.thickness, join: "round", cap: "round")
    let A = (px, py)
    let B = (px + pw, py)
    let C = (px + pw, py + ph)
    let D = (px, py + ph)
    let Bp = (px + pw + pox, py + poy)
    let Cp = (px + pw + pox, py + ph + poy)
    let Dp = (px + pox, py + ph + poy)
    line(A, B, Bp, Cp, Dp, D, close: true, stroke: s)
    if show-right { line(B, C, stroke: s) }
    line(D, C, stroke: s)
    line(C, Cp, stroke: s)
  }

  let box-3d(x, y, w, h, d, fill, opacity: 1, show-left: true, show-right: true, ylabel: none, zlabel: none, is-input: false, image: none) = {
    let (ox, oy) = get-depth-offsets(d)
    let alpha = 100% - opacity * 100%
    
    let dyn-strokes = dynamic-color-strokes(fill)

    line((x, y), (x + ox, y + oy), stroke: dyn-strokes.hidden)
    line((x + ox, y + oy), (x + w + ox, y + oy), stroke: dyn-strokes.hidden)
    line((x + ox, y + oy), (x + ox, y + h + oy), stroke: dyn-strokes.hidden)

    rect((x, y), (x + w, y + h), fill: fill.transparentize(alpha), stroke: none)

    line((x, y + h), (x + ox, y + h + oy), (x + w + ox, y + h + oy), (x + w, y + h),
      close: true, fill: fill.darken(darken-amounts.top).transparentize(alpha), stroke: none)
    line((x + w, y), (x + w + ox, y + oy), (x + w + ox, y + h + oy), (x + w, y + h),
      close: true, fill: fill.darken(darken-amounts.right).transparentize(alpha), stroke: none)

    if image != none {
      draw-isometric-image(x, y, w, h, ox, oy, image)
    }

    draw-prism-silhouette(x, y, w, h, ox, oy, dyn-strokes.solid, show-right: show-right)

    if is-input {
      if ylabel != none {
        content((x - 0.2, y + h/2), anchor: "east",
          [#text(size: scaled-font(font-sizes.layer-label), weight: "bold", str(ylabel))])
      }
      if zlabel != none {
        content((x + w/2 + ox/2, y + h + oy - 0.9), angle: depth-angle-deg,
          [#text(size: scaled-font(font-sizes.layer-label), weight: "bold", str(zlabel))])
      }
    } else {
      if ylabel != none {
        content((x - 0.3, y + h/2), anchor: "east",
          [#text(size: scaled-font(font-sizes.layer-label), str(ylabel))])
      }
      if zlabel != none {
        content((x + w/2 + ox/2, y - 0.4), angle: depth-angle-deg,
          [#text(size: scaled-font(font-sizes.layer-label), str(zlabel))])
      }
    }
  }

  // Helper function: Draw front face of a single band with optional relu split
  let draw-band-front-face(band-x, y, band-width, h, fill-color, bandfill-color, alpha, show-relu) = {
    if show-relu {
      let conv-width = band-width * 2 / 3
      rect((band-x, y), (band-x + conv-width, y + h),
        fill: fill-color.transparentize(calc.max(opacity-values.front-face, alpha)), stroke: none)
      rect((band-x + conv-width, y), (band-x + band-width, y + h),
        fill: bandfill-color.transparentize(calc.max(opacity-values.front-face, alpha)), stroke: none)
    } else {
      rect((band-x, y), (band-x + band-width, y + h),
        fill: fill-color.transparentize(calc.max(opacity-values.front-face, alpha)), stroke: none)
    }
  }
  
  // Helper function: Draw top face of a single band with optional relu split
  let draw-band-top-face(band-x, y, band-width, h, ox, oy, fill-color, bandfill-color, show-relu) = {
    if show-relu {
      let conv-width = band-width * 2 / 3
      line((band-x, y + h), (band-x + ox, y + h + oy),
        (band-x + conv-width + ox, y + h + oy), (band-x + conv-width, y + h),
        close: true,
        fill: fill-color.darken(darken-amounts.top).transparentize(opacity-values.top-face),
        stroke: none)
      line((band-x + conv-width, y + h), (band-x + conv-width + ox, y + h + oy),
        (band-x + band-width + ox, y + h + oy), (band-x + band-width, y + h),
        close: true,
        fill: bandfill-color.darken(darken-amounts.top).transparentize(opacity-values.top-face),
        stroke: none)
    } else {
      line((band-x, y + h), (band-x + ox, y + h + oy),
        (band-x + band-width + ox, y + h + oy), (band-x + band-width, y + h),
        close: true,
        fill: fill-color.darken(darken-amounts.top).transparentize(opacity-values.top-face),
        stroke: none)
    }
  }
  
  // Helper function: Draw band separator edges
  let draw-band-separator-edges(band-x, y, h, ox, oy, band-width, is-first, fill-color) = {

    let dyn-strokes = dynamic-color-strokes(fill-color)

    if is-first {
      // First band: draw the three hidden back edges
      line((band-x, y), (band-x + ox, y + oy), stroke: dyn-strokes.hidden)
      line((band-x + ox, y + oy), (band-x + ox, y + h + oy), stroke: dyn-strokes.hidden)
      line((band-x + ox, y + oy), (band-x + band-width + ox, y + oy), stroke: dyn-strokes.hidden)
    } else {
      // Front vertical separator (solid)
      line((band-x, y), (band-x, y + h), stroke: dyn-strokes.solid)
      // Diagonal connector from front top to back top (solid)
      line((band-x, y + h), (band-x + ox, y + h + oy), stroke: dyn-strokes.solid)
      // Diagonal connector from front bottom to back bottom (dashed)
      line((band-x, y), (band-x + ox, y + oy), stroke: dyn-strokes.hidden)
      // Back vertical edge (dashed)
      line((band-x + ox, y + oy), (band-x + ox, y + h + oy), stroke: dyn-strokes.hidden)
      // Back horizontal edge (dashed)
      line((band-x + ox, y + oy), (band-x + band-width + ox, y + oy), stroke: dyn-strokes.hidden)
    }
  }
  
  // Helper function: Display channels labels (single label below, second label on diagonal if provided)
  let draw-channels-labels(channels, center-x, right-x, y, ox, oy) = {
    if channels != none and channels.len() > 0 {
      // First element: display below the layer
      content((center-x, y - 0.15), 
        [#text(size: scaled-font(font-sizes.channel-number), str(channels.at(0)))])
      
      // Second element (if exists): display along depth diagonal
      if channels.len() > 1 {
        let diag-mid-x = right-x + ox / 2.5
        let diag-mid-y = y + oy / 2.5
        content((diag-mid-x, diag-mid-y - 0.23), angle: depth-angle-deg,
          [#text(size: scaled-font(font-sizes.channel-number), str(channels.at(1)))])
      }
    }
  }
  
  // Helper function: Display a layer's label.
  // `label-dx` / `label-dy` shift it from the position its layer type places it
  // at, and `label-anchor` chooses which edge of the text box is pinned there.
  // Labels are otherwise placed with no awareness of their neighbours, so on
  // tightly spaced layers this is what separates them without having to move
  // the layers apart.
  let draw-layer-label(l, label, cx, cy, size: none) = {
    if label == none { return }
    let font-size = if size == none { font-sizes.label } else { size }
    // Anchor on the baseline, not the bounding box. CeTZ measures content from
    // cap-height to baseline and then grows the box by the actual glyph bounds,
    // so a label containing descenders gets a taller box and centring it lifts
    // the text: "projection" would sit ~1pt above "convolution". Anchoring at
    // "base" pins the baseline instead, so labels align regardless of which
    // ascenders and descenders a string happens to contain.
    let body = text(size: scaled-font(font-size), weight: "bold", label)
    let px = cx + l.at("label-dx", default: 0)
    let py = cy + l.at("label-dy", default: 0)

    let orient = l.at("label-orient", default: none)
    let angle = l.at("label-angle", default: none)
    if orient != none and angle != none {
      panic("Use either label-orient or label-angle, not both. label-orient sets " +
            "the angle and the matching anchor together; label-angle leaves the " +
            "anchor to you.")
    }

    if orient == none {
      // Raw angle. The caller owns label-anchor, because the correct anchor for
      // an arbitrary rotation depends on where they want the text to sit.
      content((px, py), anchor: l.at("label-anchor", default: "base"),
        angle: if angle == none { 0deg } else { angle }, body)
    } else {
      // Preset orientations, each paired with the anchor that places it against
      // its layer correctly, so the common cases need no manual adjustment.
      // Rotation goes through std.rotate rather than CeTZ's `angle:` because
      // reflow gives the rotated text a real bounding box for the anchor to act
      // on; `angle:` rotates about the anchor and leaves the label off-centre.
      // std. is required: `import draw: *` shadows both rotate and hide.
      let presets = (
        horizontal: (rot: 0deg, anchor: "base"),
        diagonal: (rot: -45deg, anchor: "north-east"),
        vertical: (rot: -90deg, anchor: "north"),
      )
      if orient not in presets {
        panic("label-orient must be \"horizontal\", \"diagonal\" or \"vertical\"; got " +
              repr(orient) + ". For any other angle use label-angle together with " +
              "your own label-anchor.")
      }
      let preset = presets.at(orient)
      let rotated = if preset.rot == 0deg { body } else {
        std.rotate(preset.rot, reflow: true, body)
      }
      content((px, py), anchor: l.at("label-anchor", default: preset.anchor), rotated)
    }
  }

  let draw-arrow-icon(x1, y1, x2, y2, opacity: 0.7, paint: none) = {
    let dx = x2 - x1
    let dy = y2 - y1
    let len = calc.sqrt(dx * dx + dy * dy)

    if len > 0 {
      let mid-x = (x1 + x2) / 2
      let mid-y = (y1 + y2) / 2
      let ux = dx / len
      let uy = dy / len
      let px = -uy
      let py = ux

      let size = arrow-config.triangle-size
      let tip = size * 0.9
      let back = size * 0.9
      let wing = size * 0.45

      let tip-pt = (mid-x + ux * tip, mid-y + uy * tip)
      let back-mid = (mid-x - ux * back, mid-y - uy * back)
      let right-pt = (back-mid.at(0) + px * wing, back-mid.at(1) + py * wing)
      let left-pt = (back-mid.at(0) - px * wing, back-mid.at(1) - py * wing)
      let back-tip = (back-mid.at(0) + ux * back * 0.5, back-mid.at(1) + uy * back * 0.5)

      let arrow-color = if paint == none { colors.arrow } else { paint }

      line(tip-pt, right-pt, back-tip, left-pt, close: true,
        fill: arrow-color, stroke: (paint: arrow-color, thickness: strokes.arrow.thickness, join: "round"))
    }
  }
  
  let draw-segment-with-arrow(x1, y1, x2, y2, opacity: 0.7, style: none, head: true) = {
    let paint = if style == none { colors.connection } else { style.paint }
    let thickness = if style == none { strokes.connection.thickness } else { style.thickness }
    let dash = if style == none { none } else { style.dash }
    line((x1, y1), (x2, y2),
      stroke: (paint: paint, thickness: thickness, dash: dash, cap: "butt"))
    if head {
      draw-arrow-icon(x1, y1, x2, y2, opacity: opacity, paint: paint)
    }
  }

  let draw-connection-path(segments, opacity: 0.7, layers: none, layer-positions-ref: (:), show-relu: false, style: none, tail-behind: false, heads: auto) = {
    // If there are layers to draw on segment idx==1, we need to split that segment
    if layers != none and layers.len() > 0 {
      // Draw first segment (idx==0) normally
      if segments.len() > 0 {
        let seg = segments.at(0)
        draw-segment-with-arrow(seg.at(0).at(0), seg.at(0).at(1), seg.at(1).at(0), seg.at(1).at(1), opacity: opacity, style: style)
      }
      
      // Process segment idx==1 with layers
      if segments.len() > 1 {
        let seg = segments.at(1)
        let seg-start = seg.at(0)
        let seg-end = seg.at(1)
        
        // Calculate positions for all layers along the segment
        let layer-infos = ()
        for layer-spec in layers {
          let layer-type = layer-spec.at("type")
          
          if layer-type == "conv" {
            let widths = layer-spec.at("widths", default: (0.5,))
            let total-width = widths.fold(0, (acc, w) => acc + w)
            let layer-h = layer-spec.at("height", default: 2)
            let layer-d = layer-spec.at("depth", default: 2)
            let (lox, loy) = get-depth-offsets(layer-d)
            
            layer-infos.push((
              spec: layer-spec,
              width: total-width,
              height: layer-h,
              depth: layer-d,
              ox: lox,
              oy: loy,
            ))
          }
        }
        
        // Calculate positions along the segment for each layer
        let num-layers = layer-infos.len()
        let positions = ()
        for (i, info) in layer-infos.enumerate() {
          let t = (i + 1) / (num-layers + 1)
          let center-x = seg-start.at(0) + (seg-end.at(0) - seg-start.at(0)) * t
          let center-y = seg-start.at(1) + (seg-end.at(1) - seg-start.at(1)) * t
          let layer-x = center-x - info.width / 2
          let layer-y = center-y - info.height / 2 - info.oy / 2
          
          // Use true_west (depth-adjusted) for connections
          let west-x = layer-x + info.ox / 2
          let east-x = layer-x + info.width + info.ox / 2
          
          positions.push((
            x: layer-x,
            y: layer-y,
            center-x: center-x,
            center-y: center-y,
            west: (west-x, center-y),
            east: (east-x, center-y),
          ))
        }
        
        // Draw connection segments and layers in proper order (interleaved)
        // First arrow: from seg-start to first layer
        if positions.len() > 0 {
          draw-segment-with-arrow(seg-start.at(0), seg-start.at(1), positions.at(0).west.at(0), positions.at(0).west.at(1), opacity: opacity, style: style)
        }
        
        // Interleave layers and arrows in propagation order
        for (i, info) in layer-infos.enumerate() {
          let pos = positions.at(i)
          let layer-spec = info.spec
          let layer-name = layer-spec.at("name", default: none)

          let mid-x = pos.x
          let mid-y = pos.y
          let total-width = info.width
          let layer-h = info.height
          let lox = info.ox
          let loy = info.oy

          let fill-color = layer-spec.at("fill", default: colors.conv)
          let bandfill-color = layer-spec.at("bandfill", default: colors.at("conv-relu"))
          let layer-opacity = layer-spec.at("opacity", default: 1.0)
          let alpha-front = 100% - layer-opacity * 100%
          let widths = layer-spec.at("widths", default: (0.5,))
          let channels = layer-spec.at("channels", default: none)
          let layer-show-relu = layer-spec.at("show-relu", default: show-relu)

          // Use dynamic color strokes for fill-color and bandfill-color
          let dyn-strokes = dynamic-color-strokes(fill-color)
          let dyn-band-strokes = dynamic-color-strokes(bandfill-color)

          // Determine if we have a diagonal label
          let has-diagonal-label = channels != none and channels.len() == widths.len() + 1
          let diagonal-label = if has-diagonal-label { channels.at(widths.len()) } else { none }

          let cumulative-x = mid-x
          for (j, w) in widths.enumerate() {
            let band-width = w
            let band-x = cumulative-x

            draw-band-front-face(band-x, mid-y, band-width, layer-h, fill-color, bandfill-color, alpha-front, layer-show-relu)

            if channels != none and j < channels.len() {
              content((band-x + band-width / 2, mid-y - 0.15), 
          [#text(size: scaled-font(font-sizes.channel-number), str(channels.at(j)))])
            }

            cumulative-x += band-width
          }

          cumulative-x = mid-x
          for (j, w) in widths.enumerate() {
            let band-width = w
            let band-x = cumulative-x

            draw-band-top-face(band-x, mid-y, band-width, layer-h, lox, loy, fill-color, bandfill-color, layer-show-relu)

            cumulative-x += band-width
          }

          let right-face-color = if layer-show-relu { bandfill-color } else { fill-color }
          let right-face-strokes = if layer-show-relu { dyn-band-strokes } else { dyn-strokes }
          line((mid-x + total-width, mid-y), (mid-x + total-width + lox, mid-y + loy),
            (mid-x + total-width + lox, mid-y + layer-h + loy), (mid-x + total-width, mid-y + layer-h),
            close: true, fill: right-face-color.darken(darken-amounts.right).transparentize(opacity-values.right-face),
            stroke: none)

          cumulative-x = mid-x
          for (j, w) in widths.enumerate() {
            let band-width = w
            let band-x = cumulative-x
            // Use bandfill-color for band separator edges if relu, else fill-color
            let edge-strokes = if layer-show-relu { dyn-band-strokes } else { dyn-strokes }
            draw-band-separator-edges(band-x, mid-y, layer-h, lox, loy, band-width, j == 0, fill-color)
            cumulative-x += band-width
          }

          draw-prism-silhouette(mid-x, mid-y, total-width, layer-h, lox, loy, dyn-strokes.solid)
          
          let label = layer-spec.at("label", default: none)
          if label != none {
            draw-layer-label(layer-spec, label, mid-x + total-width / 2, mid-y - 0.5, size: font-sizes.layer-label)
          }
          
          // Display diagonal label if provided
          if diagonal-label != none {
            let diag-start-x = mid-x + total-width
            let diag-start-y = mid-y
            let diag-mid-x = diag-start-x + lox / 2.5
            let diag-mid-y = diag-start-y + loy / 2.5
            content((diag-mid-x, diag-mid-y - 0.23), angle: depth-angle-deg,
              [#text(size: scaled-font(font-sizes.channel-number), str(diagonal-label))])
          }
          
          if layer-name != none {
            layer-positions-ref.insert(layer-name, (
              x: mid-x, y: mid-y, w: total-width, h: layer-h, ox: lox, oy: loy,
              anchors: get-layer-anchors(mid-x, mid-y, total-width, layer-h, lox, loy)
            ))
          }
          
          // Draw arrow to next layer (or to seg-end if this is the last layer)
          if i < layer-infos.len() - 1 {
            // Arrow to next layer
            let from-east = positions.at(i).east
            let to-west = positions.at(i + 1).west
            draw-segment-with-arrow(from-east.at(0), from-east.at(1), to-west.at(0), to-west.at(1), opacity: opacity, style: style)
          } else {
            // Last layer: arrow to seg-end
            draw-segment-with-arrow(positions.at(-1).east.at(0), positions.at(-1).east.at(1), seg-end.at(0), seg-end.at(1), opacity: opacity, style: style)
          }
        }
      }
      
      // Draw remaining segments (idx >= 2) normally
      for idx in range(2, segments.len()) {
        let seg = segments.at(idx)
        draw-segment-with-arrow(seg.at(0).at(0), seg.at(0).at(1), seg.at(1).at(0), seg.at(1).at(1), opacity: opacity, style: style)
      }
    } else {
      // No layers, draw all segments normally
      for (si, seg) in segments.enumerate() {
        let last = si == segments.len() - 1
        let seg-head = if heads == auto { true } else { heads.at(si, default: true) }
        if tail-behind and last {
          // The arrival edge is on the far side of the block, so the tail of the
          // route passes underneath it. Drawing it on top makes the line look
          // like it runs across the front face instead of arriving behind.
          on-layer(-1, draw-segment-with-arrow(seg.at(0).at(0), seg.at(0).at(1), seg.at(1).at(0), seg.at(1).at(1), opacity: opacity, style: style, head: seg-head))
        } else {
          draw-segment-with-arrow(seg.at(0).at(0), seg.at(0).at(1), seg.at(1).at(0), seg.at(1).at(1), opacity: opacity, style: style, head: seg-head)
        }
      }
    }

    // Round join at each interior waypoint cleans the elbows; terminations stay flat.
    for i in range(segments.len() - 1) {
      let v = segments.at(i).at(1)
      let a = segments.at(i).at(0)
      let b = segments.at(i + 1).at(1)
      let da = (a.at(0) - v.at(0), a.at(1) - v.at(1))
      let db = (b.at(0) - v.at(0), b.at(1) - v.at(1))
      let la = calc.max(calc.sqrt(da.at(0) * da.at(0) + da.at(1) * da.at(1)), 0.001)
      let lb = calc.max(calc.sqrt(db.at(0) * db.at(0) + db.at(1) * db.at(1)), 0.001)
      let stub = 0.12
      // Takes the connection's paint and width, or a styled route gets a stub in
      // the default colour and weight sitting on top of it. Deliberately solid
      // even on a dashed route: the stub exists to fill the join, and a dash
      // pattern this short would leave the notch it is there to hide.
      let stub-paint = if style == none { colors.connection } else { style.paint }
      let stub-thickness = if style == none { strokes.connection.thickness } else { style.thickness }
      line(
        (v.at(0) + da.at(0) / la * stub, v.at(1) + da.at(1) / la * stub),
        v,
        (v.at(0) + db.at(0) / lb * stub, v.at(1) + db.at(1) / lb * stub),
        stroke: (paint: stub-paint, thickness: stub-thickness, join: "round", cap: "butt"),
      )
    }
  }
  
  let arrow-axis-y = arrow-config.axis-y

  // Walk a run of layers, drawing them and reporting what the rest of the
  // figure needs to know about them.
  //
  // Extracted so that a run can be walked somewhere other than along the main
  // axis. The layout state was previously implicit in this function body, which
  // meant there was exactly one trunk and it always started at the origin.
  //
  // Typst closures capture by value, so nothing here leaks outward: everything
  // the caller needs is returned, and the drawing is returned as content rather
  // than emitted, so the caller decides where it goes.
  let walk-trunk(layers, start-x, arrow-axis-y) = {
    let x = start-x
    let first-west = none
    let max-half-extent = 0
    let prev-layer-depth = 0
    // Layers a connection lands on, so `offset: auto` can leave them room.
    let connection-targets = connections.map(c => c.at("to", default: none)).filter(n => n != none)
    let prev-center-y = arrow-axis-y
    let prev-x = 0
    let prev-depth-offset = 0
    let prev-pool-width = 0
    let used-layer-types = (:)
    let layer-positions = (:)
    let arrow-segments = (:)
    let legend-entries = ()  // Collect legend entries in order of appearance: array of (key, label, color, ...)
  
    // Default legend labels for each layer type
    let default-legend-labels = (
      input: "Input",
      conv: "Convolution",
      convres: "Conv Residual",
      pool: "Pooling",
      unpool: "Unpooling",
      deconv: "Deconvolution",
      concat: "Concatenation",
      sum: "Element-wise Sum",
      gap: "Global Avg Pool",
      fc: "Fully Connected",
      convsoftmax: "Conv Softmax",
      softmax: "Softmax",
      output: "Output",
    )
  

    let body = {
      for (i, l) in layers.enumerate() {
        // A parallel section: each branch is a layer list of its own, walked at
        // its own height and rejoined afterwards.
        //
        // draw-network advances one cursor along one axis, so anything genuinely
        // parallel had to be collapsed into a single block with arrows pointed at
        // it. Walking a branch is the same operation as walking the trunk, only
        // starting somewhere else, which is what extracting walk-trunk made
        // expressible. The call is recursive, so a branch may contain branches.
        if l.type == "branch" {
          let subs = l.at("branches", default: ())
          let spread = l.at("spread", default: 6)
          let lead = l.at("lead", default: 2.0)
          let n = subs.len()
          // "depth" stacks the branches along the projection's own axis rather
          // than straight up: the front branch stays on the trunk line and the
          // rest step back and up along the direction the blocks are sheared.
          // The fan-out and rejoin are then two parallel 45-degree spines with
          // horizontals between them, a parallelogram, rather than the mirrored
          // hexagon a vertical split produces. Neither 45 is a free angle: it is
          // the one the projection itself uses.
          let depth-spread = l.at("spread-mode", default: "vertical") == "depth"
          // The turn has to clear the preceding block's sheared face, not just
          // its front edge, or the run across is drawn over it.
          let turn-out = calc.max(x + lead / 2, prev-x + prev-depth-offset + 0.15)
          // Both ends sit half a depth inside the block, which is where the axis
          // arrows start and finish. Using the outer edges instead made the route
          // stop dead at the face rather than running under it and being covered,
          // so a branch read as detached where an ordinary layer reads as joined.
          let branch-from-x = prev-x + prev-pool-width + prev-depth-offset / 2
          let branch-from-y = prev-center-y
          let branch-start = turn-out + lead / 2
          let ends = ()

          // The outgoing spine, drawn once: the teeth into each branch leave
          // from points along it. It crosses the axis midway, so the flow reads
          // as arriving and splitting away and near, and the two half-spines
          // carry arrows radiating from that crossing.
          let spine-cross = turn-out + spread / 2
          // A filled dot marks the point where the flow divides, and its twin
          // below marks where it meets again. Several routes pass through these
          // points, so without a marker the crossing reads as incidental overlap
          // rather than as a junction.
          let junction(px, py) = circle((px, py), radius: 0.09, fill: colors.connection, stroke: none)
          if depth-spread and n > 1 {
            draw-connection-path((((branch-from-x, branch-from-y), (spine-cross, branch-from-y)),), opacity: 0.7)
            draw-connection-path((((spine-cross, branch-from-y), (turn-out + spread, branch-from-y + spread / 2)),), opacity: 0.7)
            draw-connection-path((((spine-cross, branch-from-y), (turn-out, branch-from-y - spread / 2)),), opacity: 0.7)
            junction(spine-cross, branch-from-y)
          }

          for (bi, sub) in subs.enumerate() {
            // Centred on the trunk, first branch highest. In depth mode the
            // offset applies to x and y equally, anchored so the front branch
            // sits on the trunk line itself.
            let k = if n <= 1 { 0 } else { spread * ((n - 1) / 2 - bi) / (n - 1) }
            // Centred: as many branches near as away, and an even count leaves
            // the trunk line itself empty. dy is symmetric about the axis; dx
            // carries the extra half-spread so the near branch is not pushed
            // left into the block the split leaves from.
            let dx = if depth-spread and n > 1 { k + spread / 2 } else { 0 }
            let dy = k
            let r = walk-trunk(sub, branch-start + dx, arrow-axis-y + dy)

            for (k, v) in r.positions { layer-positions.insert(k, v) }
            for (k, v) in r.segments { arrow-segments.insert(k, v) }
            for e in r.legend {
              if not legend-entries.any(q => q.key == e.key) { legend-entries.push(e) }
            }
            // A branch sits off-axis, so its reach from the trunk is its own
            // reach plus however far it was displaced.
            max-half-extent = calc.max(max-half-extent, r.max-half-extent + calc.abs(dy))

            // Anchored like the axis arrows: leaving from the previous block's
            // perspective centre, arriving where the branch's first block wants
            // its arrow. Aiming at the branch axis instead put the route across
            // the block's face.
            let (in-x, in-y) = if r.first-west == none {
              (branch-start + dx, arrow-axis-y + dy)
            } else { r.first-west }
            let turn = turn-out
            if depth-spread {
              // A horizontal tooth from the spine into the branch. The front
              // branch is on the trunk line, so its tooth is the trunk's own
              // continuation from the block it left.
              let from = if n <= 1 { (branch-from-x, branch-from-y) } else { (turn + dx, branch-from-y + dy) }
              draw-connection-path(((from, (in-x, in-y)),), opacity: 0.7)
              // Where the tooth leaves the spine is a junction on the inner
              // rows, since the spine passes through on its way to the outer
              // ones. The outermost rows are corners, and the axis row's point
              // is the crossing dot already drawn.
              if bi != 0 and bi != n - 1 and calc.abs(dy) > 0.001 {
                junction(turn + dx, branch-from-y + dy)
              }
            } else if calc.abs(in-y - branch-from-y) < 0.001 {
              // The on-axis branch's tooth starts at the split dot, not at the
              // source block. Drawn from the block it would run through the dot
              // and its mid-segment head would sit just past the dot instead of
              // centred between the dot and the branch.
              let from-x = if n <= 1 { branch-from-x } else { turn }
              draw-connection-path((((from-x, branch-from-y), (in-x, in-y)),), opacity: 0.7)
            } else {
              draw-connection-path((
                ((branch-from-x, branch-from-y), (turn, branch-from-y)),
                ((turn, branch-from-y), (turn, in-y)),
                ((turn, in-y), (in-x, in-y)),
              ), opacity: 0.7)
              junction(turn, branch-from-y)
            }
            // Drawn after the route, so the blocks cover it the way a layer
            // covers the arrow arriving at it.
            r.body

            // The tooth is this branch's incoming arrow. Registering it means a
            // connection aimed at the branch's first layer lands on the tooth at
            // its arrowhead, the same way a connection to a trunk layer lands on
            // the axis arrow in front of it, instead of falling back to a point
            // half a depth inside the block.
            let first-name = if sub.len() > 0 { sub.first().at("name", default: none) } else { none }
            if first-name != none and first-name + "-in" not in arrow-segments {
              let tooth-start-x = if depth-spread {
                if n <= 1 { branch-from-x } else { turn + dx }
              } else {
                if n <= 1 { branch-from-x } else { turn }
              }
              let mid = ((tooth-start-x + in-x) / 2, in-y)
              arrow-segments.insert(first-name + "-in", (end: (in-x, in-y), mid: mid, x: mid.at(0), y: mid.at(1)))
            }
            let last-name = if sub.len() > 0 { sub.last().at("name", default: none) } else { none }
            ends.push((x: r.prev-x + r.prev-depth-offset / 2, shear: r.prev-depth-offset / 2, y: r.prev-center-y, dy: dy, dx: dx, bi: bi, last-name: last-name, end: r.end-x))
          }

          // Rejoin where the longest branch finishes, so none is cut short.
          // Measured from the sheared right edge of each branch's last block, so
          // the rejoin turns clear of them too.
          let rturn0 = ends.map(e => e.x + e.shear - e.at("dx", default: 0)).fold(branch-start, calc.max) + lead / 2
          let rcross = rturn0 + spread / 2
          let resume = if depth-spread {
            rcross + lead / 2
          } else {
            ends.map(e => e.x + e.shear).fold(x, calc.max) + lead
          }
          if depth-spread {
            // The incoming spine mirrors the outgoing one: exits run onto it
            // horizontally, the away half comes forward and the near half rises,
            // meeting on the axis and continuing to the resume point.
            for e in ends {
              let out-x = if n <= 1 { resume } else { rturn0 + e.dx }
              if n <= 1 {
                draw-connection-path((((e.x, e.y), (resume, arrow-axis-y)),), opacity: 0.7)
              } else {
                draw-connection-path((((e.x, e.y), (out-x, e.y)),), opacity: 0.7)
              }
              if e.last-name != none and e.last-name + "-out" not in arrow-segments {
                let mid = ((e.x + out-x) / 2, e.y)
                arrow-segments.insert(e.last-name + "-out", (start: (e.x, e.y), mid: mid, x: mid.at(0), y: mid.at(1)))
              }
              if e.bi != 0 and e.bi != n - 1 and calc.abs(e.dy) > 0.001 {
                junction(out-x, e.y)
              }
            }
            if n > 1 {
              draw-connection-path((((rturn0 + spread, arrow-axis-y + spread / 2), (rcross, arrow-axis-y)),), opacity: 0.7)
              draw-connection-path((((rturn0, arrow-axis-y - spread / 2), (rcross, arrow-axis-y)),), opacity: 0.7)
              junction(rcross, arrow-axis-y)
            }
          } else {
            for e in ends {
              let turn = resume - lead / 2
              let out-x = if n <= 1 { resume } else { turn }
              if e.last-name != none and e.last-name + "-out" not in arrow-segments {
                let mid = ((e.x + out-x) / 2, e.y)
                arrow-segments.insert(e.last-name + "-out", (start: (e.x, e.y), mid: mid, x: mid.at(0), y: mid.at(1)))
              }
              // Routes end at the junction. The stretch from the dot to the
              // next block is the trunk's own arrow, drawn once by the next
              // layer, so it carries a single head rather than one per branch.
              if n <= 1 {
                draw-connection-path((((e.x, e.y), (resume, arrow-axis-y)),), opacity: 0.7)
              } else if e.dy == 0 {
                draw-connection-path((((e.x, e.y), (turn, arrow-axis-y)),), opacity: 0.7)
              } else {
                draw-connection-path((
                  ((e.x, e.y), (turn, e.y)),
                  ((turn, e.y), (turn, arrow-axis-y)),
                ), opacity: 0.7)
                junction(turn, arrow-axis-y)
              }
            }
          }

          let dot-x = if n <= 1 { resume } else if depth-spread { rcross } else { resume - lead / 2 }
          // The arrow into the next block leaves from the merge dot, but the
          // drawing extends past it: in depth mode the away rows and their spine
          // reach spread/2 further right. The cursor advances past all of it so
          // the next block clears the parallelogram, while prev-x stays at the
          // dot so the trunk arrow still originates there.
          x = if depth-spread and n > 1 { rturn0 + spread } else { dot-x }
          prev-x = dot-x
          prev-depth-offset = 0
          prev-center-y = arrow-axis-y
          prev-pool-width = 0
          prev-layer-depth = 0
          continue
        }

        used-layer-types.insert(l.type, true)

        // Where an arrow arriving at this run should land. Only the first layer
        // needs it, and only a caller placing this run somewhere other than the
        // main axis will ask.
        if first-west == none {
          let (f-ox, f-oy) = get-depth-offsets(l.at("depth", default: 5))
          let f-h = l.at("height", default: 5)
          let f-y = get-y-offset-for-center-on-axis(f-h, l.at("depth", default: 5), arrow-axis-y)
          first-west = (x + f-ox / 2, get-perspective-center-y(f-y, f-h, f-oy))
        }
    
        // Ensure height and depth are set for arrow calculation (using type-specific defaults)
        // A layer may state its tensor shape as (channels, height, width) and have
        // its geometry derived from it, rather than being sized by eye.
        //
        // Both axes are logarithmic. Linear spatial extent is unusable: against the
        // pyramid in the YOLO example, a 20-square block comes out a quarter of a
        // unit tall against 8 for the 640-square input, which is invisible. The log
        // mapping reproduces that hand-tuned pyramid to within 0.4 units, and the
        // channel mapping its widths to within 0.05.
        //
        // Shape supplies defaults, not values. Anything stated explicitly wins,
        // field by field, so a layer can take its width and depth from its shape
        // while its height is forced. Absent `shape` none of this runs.
        let shp = l.at("shape", default: none)
        if shp != none {
          if shp.len() != 3 {
            panic("shape must be (channels, height, width); got " + repr(shp))
          }
          let (shp-c, shp-h, shp-w) = shp
          // Floored: the mapping goes negative for very small extents, and a layer
          // still has to be visible.
          let from-spatial(v) = calc.max(
            shape-scale.spatial.at(0) * calc.log(calc.max(v, 1), base: 2) + shape-scale.spatial.at(1), 0.4)
          let from-channels(v) = calc.max(
            shape-scale.channels.at(0) * calc.log(calc.max(v, 1), base: 2) + shape-scale.channels.at(1), 0.15)

          if not l.keys().contains("height") { l.insert("height", from-spatial(shp-h)) }
          if not l.keys().contains("depth") { l.insert("depth", from-spatial(shp-w)) }
          // Only the types whose thickness means channel count take a derived width.
          // The rest have a fixed thickness that says something else.
          if not l.keys().contains("widths") and not l.keys().contains("width") {
            if l.type == "conv" or l.type == "convres" {
              l.insert("widths", (from-channels(shp-c),))
            } else if l.type == "custom" {
              l.insert("width", from-channels(shp-c))
            }
          }
        }

        if not l.keys().contains("height") {
          let default-h = if l.type == "pool" or l.type == "unpool" { 4 } else if l.type == "concat" or l.type == "fc" or l.type == "softmax" or l.type == "output" { 3 } else if l.type == "gap" { 1.5 } else if l.type == "convsoftmax" { 4 } else { 5 }
          l.insert("height", default-h)
        }
        if not l.keys().contains("depth") {
          let default-d = if l.type == "pool" or l.type == "unpool" { 4 } else if l.type == "concat" { 3 } else if l.type == "gap" { 1.5 } else if l.type == "fc" or l.type == "softmax" or l.type == "output" { 0.4 } else if l.type == "convsoftmax" { 4 } else { 5 }
          l.insert("depth", default-d)
        }

        // Track the greatest reach of any layer from the axis, front-bottom to
        // back-top. `pos: auto` uses it to sit clear of every block instead of at a
        // height the author has to work out from the layer dimensions.
        let (_, l-oy) = get-depth-offsets(l.depth)
        max-half-extent = calc.max(max-half-extent, l.height / 2 + l-oy / 2)
    
        // `offset: auto` leaves the spacing to the drawing rather than to the author.
        //
        // The offset has to cover the previous layer's isometric lean before it buys
        // any visible space at all, and a gap a connection descends into has to be
        // wider still or the route arrives inside that layer's sheared top face.
        // Both are computable here: the previous depth is known, and the connection
        // list says whether anything lands in this gap. A figure that works them out
        // for itself ends up restating the size pyramid twice, once in the layers
        // and once in the offsets, with nothing to catch them drifting apart.
        let auto-offset = {
          let base = depth-shear(prev-layer-depth, depth-multiplier: depth-multiplier) + auto-gap
          if l.at("name", default: none) in connection-targets {
            calc.max(base, min-clear-offset(prev-layer-depth, depth-multiplier: depth-multiplier))
          } else {
            base
          }
        }
        let gap = if i == 0 {
          0
        } else if l.type == "pool" or l.type == "unpool" {
          // These position themselves against the block they attach to, further down.
          0
        } else {
          let stated = l.at("offset", default: 1.2)
          if stated == auto { auto-offset } else { stated }
        }
    
        x += gap
        // Only after the gap is resolved, so it still refers to the layer before.
        prev-layer-depth = l.depth
    
        // Calculate and store arrow segment positions for ALL layers (for skip connections)
        // Only draw arrows if previous layer has show-connection enabled (controls outgoing arrows)
        if i > 0 {
          let prev-layer = layers.at(i - 1)
          let prev-show-connection = prev-layer.at("show-connection", default: if prev-layer.type == "input" { false } else { true })
          if prev-show-connection {
            // Arrow starts from true_east of previous layer (depth-adjusted)
            let start-x = prev-x + prev-pool-width + prev-depth-offset / 2
            let start-y = prev-center-y
        
            // Read height and depth directly from layer (already set by each layer type)
            let curr-h = l.at("height")
            let curr-d = l.at("depth")
            let (curr-ox, curr-oy) = get-depth-offsets(curr-d)
            let curr-depth-offset = curr-ox
            let curr-y-offset = get-y-offset-for-center-on-axis(curr-h, curr-d, arrow-axis-y)
            let end-y = get-perspective-center-y(curr-y-offset, curr-h, curr-oy)
        
            // Arrow ends at true_west of current layer (depth-adjusted)
            // Special handling for sum node (use radius instead of depth)
            let end-x = if l.type == "sum" {
              let radius = l.at("radius", default: 0.4)
              x + prev-depth-offset / 2
            } else {
              // For pool/unpool with offset, calculate actual layer position first
              let is-curr-pool-or-unpool = l.type == "pool" or l.type == "unpool"
              let stated-offset = { let o = l.at("offset", default: none); if o == auto { auto-offset } else { o } }
              let curr-offset = if is-curr-pool-or-unpool { stated-offset } else { none }
              let curr-layer-x = if curr-offset != none { x + curr-offset } else if is-curr-pool-or-unpool { x + prev-depth-offset / 2 - curr-ox / 2 } else { x }
              curr-layer-x + curr-depth-offset / 2
            }
        
            let prev-name = prev-layer.at("name", default: none)
            let curr-name = l.at("name", default: none)
        
            // Store true arrow endpoints (with depth) and midpoint
            let mid-arrow-x = (start-x + end-x) / 2
            let mid-arrow-y = (start-y + end-y) / 2
        
            // Store as outgoing arrow for previous layer (includes start point and midpoint)
            if prev-name != none {
              arrow-segments.insert(prev-name + "-out", (
                start: (start-x, start-y),
                mid: (mid-arrow-x, mid-arrow-y),
                x: mid-arrow-x, 
                y: mid-arrow-y
              ))
            }
            // Store as incoming arrow for current layer (includes end point and midpoint)
            if curr-name != none {
              arrow-segments.insert(curr-name + "-in", (
                end: (end-x, end-y),
                mid: (mid-arrow-x, mid-arrow-y),
                x: mid-arrow-x,
                y: mid-arrow-y
              ))
            }
        
            // Draw arrow for non-pool/unpool layers, or pool/unpool with offset
            let is-pool-or-unpool = l.type == "pool" or l.type == "unpool"
            let has-offset = l.at("offset", default: none) != none
            if not is-pool-or-unpool or has-offset {
              draw-segment-with-arrow(start-x, start-y, end-x, end-y, opacity: 0.7)
          
              // Draw connection label if specified (read from previous layer, like show-connection)
              let conn-label = prev-layer.at("connection-label", default: none)
              if conn-label != none {
                content((mid-arrow-x, mid-arrow-y + 0.28), 
                  [#text(size: scaled-font(font-sizes.layer-label), conn-label)])
              }
            }
          }
        }
    
        // Where this layer starts, so its drawn width can be recovered afterwards
        // without every layer type having to report it.
        let repeat-x0 = x

        // CUSTOM LAYER (Universal layer type with full flexibility)
        if l.type == "custom" {
          let h = l.at("height", default: 5)
          let d = l.at("depth", default: 5)
          l.insert("height", h)
          l.insert("depth", d)
          let w = l.at("width", default: none)
          let widths = l.at("widths", default: none)
          let label = l.at("label", default: none)
          let xlabel = l.at("xlabel", default: none)
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.custom)
          // When a band is drawn but no bandfill was declared, derive it from the
          // layer's own fill. The palette's custom-relu is the companion of the
          // default custom grey, so using it against a user-supplied fill produces
          // a band unrelated to the layer's color.
          let bandfill-color = if "bandfill" in l {
            l.at("bandfill")
          } else if "fill" in l {
            fill-color.darken(25%)
          } else {
            colors.at("custom-relu")
          }
          let layer-opacity = l.at("opacity", default: 0.7)
          let channels = l.at("channels", default: none)
          let ylabel-val = l.at("ylabel", default: none)
          let zlabel-val = l.at("zlabel", default: none)
          // A custom layer inherits the network-level show-relu only when it has an
          // activation band to show. An explicit per-layer show-relu still opts in.
          let layer-show-relu = if "show-relu" in l {
            l.at("show-relu")
          } else {
            show-relu and "bandfill" in l
          }
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let img = l.at("image", default: none)
          let is-input-style = l.at("input-style", default: false)
      
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)
      
          // Determine rendering mode: simple box or multi-band
          let use-simple-box = widths == none
      
          if use-simple-box {
            // Simple box rendering (like input, pool, fc, etc.)
            let actual-w = if w == none { 0.2 } else { w }
        
            if img == "default" {
              img = image("bird.jpg")
            }
        
            box-3d(x, y-offset, actual-w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)
        
            // Display channels labels
            draw-channels-labels(channels, x + actual-w/2, x + actual-w, y-offset, ox, oy)
        
            // Track position if named
            if name != none {
              layer-positions.insert(name, (
                x: x, y: y-offset, w: actual-w, h: h, ox: ox, oy: oy, type: "custom",
                anchors: get-layer-anchors(x, y-offset, actual-w, h, ox, oy),
                pool-offset: 0
              ))
            }
        
            if label != none {
              draw-layer-label(l, label, x + actual-w/2, y-offset - 0.5)
            }
        
            prev-x = x + actual-w
            prev-depth-offset = ox
            x += actual-w
            prev-center-y = get-perspective-center-y(y-offset, h, oy)
            prev-pool-width = 0
          } else {
            // Multi-band rendering (like conv, convres)
            let dyn-strokes = dynamic-color-strokes(fill-color)
            let dyn-band-strokes = dynamic-color-strokes(bandfill-color)
        
            let has-diagonal-label = channels != none and channels.len() == widths.len() + 1
            let diagonal-label = if has-diagonal-label { channels.at(widths.len()) } else { none }
            let channel-labels = if channels != none {
              if has-diagonal-label { channels.slice(0, widths.len()) } else { channels }
            } else {
              (widths.map(w => ""))
            }
        
            let start-x = x
            let total-width = widths.fold(0, (acc, w) => acc + w)
        
            // Draw front face as colored bands
            let cumulative-x = start-x
            let alpha-front = 100% - layer-opacity * 100%
            for (j, ch) in channel-labels.enumerate() {
              let band-width = widths.at(j)
              let band-x = cumulative-x
          
              draw-band-front-face(band-x, y-offset, band-width, h, fill-color, bandfill-color, alpha-front, layer-show-relu)
          
              // Display channel label under each band
              let band-center-x = band-x + band-width / 2
              content((band-center-x, y-offset - 0.15), 
                [#text(size: scaled-font(font-sizes.channel-number), str(ch))])
          
              cumulative-x += band-width
            }
        
            // Draw top face segmented by band
            cumulative-x = start-x
            for (j, ch) in channel-labels.enumerate() {
              let band-width = widths.at(j)
              let band-x = cumulative-x
          
              draw-band-top-face(band-x, y-offset, band-width, h, ox, oy, fill-color, bandfill-color, layer-show-relu)
          
              cumulative-x += band-width
            }
        
            // Draw right face
            let right-face-color = if layer-show-relu { bandfill-color } else { fill-color }
            line((start-x + total-width, y-offset), (start-x + total-width + ox, y-offset + oy),
              (start-x + total-width + ox, y-offset + h + oy), (start-x + total-width, y-offset + h),
              close: true,
              fill: right-face-color.darken(darken-amounts.right).transparentize(opacity-values.right-face),
              stroke: none)
        
            // Draw image on top of right face if provided
            if img != none {
              draw-isometric-image(start-x, y-offset, total-width, h, ox, oy, img)
            }
        
            // Draw all edges for band divisions
            cumulative-x = start-x
            for (j, ch) in channel-labels.enumerate() {
              let band-width = widths.at(j)
              let band-x = cumulative-x
          
              draw-band-separator-edges(band-x, y-offset, h, ox, oy, band-width, j == 0, fill-color)
          
            cumulative-x += band-width
          }
      
          draw-prism-silhouette(start-x, y-offset, total-width, h, ox, oy, dyn-strokes.solid)
      
          prev-x = start-x + total-width
            prev-depth-offset = ox
            x = start-x + total-width
            let center-x = start-x + total-width / 2
        
            // Display label below channel numbers
            if label != none {
              draw-layer-label(l, label, center-x, y-offset - 0.5, size: font-sizes.layer-label)
            }
        
            // Display xlabel if provided
            if xlabel != none {
              content((center-x, y-offset - 0.8), 
                [#text(size: scaled-font(font-sizes.layer-label), xlabel)])
            }
        
            // Display ylabel and zlabel if provided
            if ylabel-val != none {
              content((start-x - 0.4, y-offset + h/2), anchor: "east",
                [#text(size: scaled-font(font-sizes.layer-label), str(ylabel-val))])
            }
            if zlabel-val != none {
              content((start-x + total-width + ox + 0.4, y-offset + h/2 + oy/2), anchor: "west",
                [#text(size: scaled-font(font-sizes.layer-label), str(zlabel-val))])
            }
        
            // Display diagonal label if provided
            if diagonal-label != none {
              let diag-start-x = start-x + total-width
              let diag-start-y = y-offset
              let diag-mid-x = diag-start-x + ox / 2.5
              let diag-mid-y = diag-start-y + oy / 2.5
              content((diag-mid-x, diag-mid-y - 0.23), angle: depth-angle-deg,
                [#text(size: scaled-font(font-sizes.channel-number), str(diagonal-label))])
            }
        
            // Track position if named
            if name != none {
              layer-positions.insert(name, (
                x: start-x, y: y-offset, w: total-width, h: h, ox: ox, oy: oy, type: "custom",
                anchors: get-layer-anchors(start-x, y-offset, total-width, h, ox, oy),
                pool-offset: 0
              ))
            }
        
            prev-center-y = get-perspective-center-y(y-offset, h, oy)
            prev-pool-width = 0
          }
      
          // Register legend entry for custom layers (only if legend parameter is provided)
          let custom-legend = l.at("legend", default: none)
          if custom-legend != none {
            // Use a unique key for each custom legend entry (legend text + color)
            let legend-key = "custom-" + str(custom-legend) + "-" + str(fill-color.to-hex())
            if not legend-entries.any(e => e.key == legend-key) {
              legend-entries.push((key: legend-key, label: custom-legend, color: fill-color, bandfill: bandfill-color, show-relu: layer-show-relu, opacity: layer-opacity))
            }
          }
        }
    
        // INPUT IMAGE - uses custom type with input-specific defaults
        else if l.type == "input" {
          // Re-route to custom handler with input defaults
          l.insert("type", "custom")
          if not l.keys().contains("width") { l.insert("width", 0) }
          if not l.keys().contains("fill") { l.insert("fill", colors.input) }
          if not l.keys().contains("opacity") { l.insert("opacity", 0.9) }
          if not l.keys().contains("input-style") { l.insert("input-style", true) }
          if not l.keys().contains("show-connection") { l.insert("show-connection", false) }
      
          // Fall through to process as custom (handled by previous if block)
          // But since we're in else-if, we need to inline the custom logic
          let h = l.at("height", default: 5)
          let d = l.at("depth", default: 5)
          l.insert("height", h)
          l.insert("depth", d)
          let w = l.at("width", default: 0)
          let label = l.at("label", default: none)
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.input)
          let layer-opacity = l.at("opacity", default: 0.9)
          let layer-show-connection = l.at("show-connection", default: false)
          let connection-label = l.at("connection-label", default: none)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)
      
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)
      
          if img == "default" {
            img = image("bird.jpg")
          }

          // Special rendering for INPUT: draw image first, then highly transparent face on top
          if img != none {
            // Draw isometric image first
            draw-isometric-image(x, y-offset, w, h, ox, oy, img)
        
            // Then draw highly transparent right face on top
            let alpha-right = layer-opacity * 100%
            line((x + w, y-offset), (x + w + ox, y-offset + oy),
              (x + w + ox, y-offset + h + oy), (x + w, y-offset + h),
              close: true,
              fill: fill-color.darken(darken-amounts.right).transparentize(alpha-right),
              stroke: dynamic-color-strokes(fill-color).solid)
          } else {
            // No image: use standard box-3d rendering
            box-3d(x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)
          }
      
          draw-channels-labels(channels, x + w/2, x + w, y-offset, ox, oy)
      
          if name != none {
            layer-positions.insert(name, (
              x: x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: "input",
              anchors: get-layer-anchors(x, y-offset, w, h, ox, oy),
              pool-offset: 0
            ))
          }
      
          if label != none {
            draw-layer-label(l, label, x + w/2, y-offset - 0.8)
          }
      
          prev-x = x + w
          prev-depth-offset = ox
          x += w
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0
      
          // Register legend entry (check for legend parameter override)
          let layer-legend = l.at("legend", default: default-legend-labels.at("input"))
          if not legend-entries.any(e => e.key == "input") {
            legend-entries.push((key: "input", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }
    
        // CONVOLUTIONAL BLOCK types - delegates to custom with conv-specific defaults
        else if l.type == "conv" or l.type == "convres"{
          let fill-color = if l.type == "conv" {
            l.at("fill", default: colors.conv)
            } else if l.type == "convres" {
            l.at("fill", default: colors.convres)
          }
          let bandfill-color = if l.type == "conv" {
            l.at("bandfill", default: colors.at("conv-relu"))
            } else if l.type == "convres" {
            l.at("bandfill", default: colors.at("convres-relu"))
          }
      
          // Set up parameters for custom handler with conv defaults
          if not l.keys().contains("fill") { l.insert("fill", fill-color) }
          if not l.keys().contains("bandfill") { l.insert("bandfill", bandfill-color) }
          if not l.keys().contains("widths") { l.insert("widths", (1,)) }
          let channels = l.at("channels", default: none)
          let widths = l.at("widths", default: (1,))
          let h = l.at("height", default: 5)
          let d = l.at("depth", default: 5)
          l.insert("height", h)
          l.insert("depth", d)
          let label = l.at("label", default: none)
          let xlabel = l.at("xlabel", default: none)
          let name = l.at("name", default: none)
          let layer-opacity = l.at("opacity", default: 1.0)
          let ylabel-val = l.at("ylabel", default: none)
          let zlabel-val = l.at("zlabel", default: none)
          let layer-show-relu = l.at("show-relu", default: show-relu)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let img = l.at("image", default: none)
      
          if img == "default" {
            img = image("bird.jpg")
          }
      
          // Use dynamic color strokes for fill-color and bandfill-color
          let dyn-strokes = dynamic-color-strokes(fill-color)
          let dyn-band-strokes = dynamic-color-strokes(bandfill-color)

          // Determine if we have a diagonal label (channels has one extra element)
          let has-diagonal-label = channels != none and channels.len() == widths.len() + 1
          let diagonal-label = if has-diagonal-label { channels.at(widths.len()) } else { none }
          let channel-labels = if channels != none {
            if has-diagonal-label { channels.slice(0, widths.len()) } else { channels }
          } else {
            (widths.map(w => ""))
          }
      
          // Use actual widths values to determine band sizes
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)
          let start-x = x
          let total-width = widths.fold(0, (acc, w) => acc + w)
      
          // Draw front face as colored bands
          let cumulative-x = start-x
          let alpha-front = 100% - layer-opacity * 100%
          for (j, ch) in channel-labels.enumerate() {
            let band-width = widths.at(j)
            let band-x = cumulative-x
        
            draw-band-front-face(band-x, y-offset, band-width, h, fill-color, bandfill-color, alpha-front, layer-show-relu)
        
            // Display channel label under each band
            let band-center-x = band-x + band-width / 2
            content((band-center-x, y-offset - 0.15), 
              [#text(size: scaled-font(font-sizes.channel-number), str(ch))])
        
            cumulative-x += band-width
          }
      
          // Draw top face segmented by band
          cumulative-x = start-x
          for (j, ch) in channel-labels.enumerate() {
            let band-width = widths.at(j)
            let band-x = cumulative-x
        
            draw-band-top-face(band-x, y-offset, band-width, h, ox, oy, fill-color, bandfill-color, layer-show-relu)
        
            cumulative-x += band-width
          }

          // Draw right face
          let right-face-color = if layer-show-relu { bandfill-color } else { fill-color }
          line((start-x + total-width, y-offset), (start-x + total-width + ox, y-offset + oy),
            (start-x + total-width + ox, y-offset + h + oy), (start-x + total-width, y-offset + h),
            close: true,
            fill: right-face-color.darken(darken-amounts.right).transparentize(opacity-values.right-face),
            stroke: none)
      
          // Draw image on top of right face if provided
          if img != none {
            draw-isometric-image(start-x, y-offset, total-width, h, ox, oy, img)
          }

          // Draw all edges for band divisions (once each)
          cumulative-x = start-x
          for (j, ch) in channel-labels.enumerate() {
            let band-width = widths.at(j)
            let band-x = cumulative-x
        
            draw-band-separator-edges(band-x, y-offset, h, ox, oy, band-width, j == 0, fill-color)
        
            cumulative-x += band-width
          }
      
          draw-prism-silhouette(start-x, y-offset, total-width, h, ox, oy, dyn-strokes.solid)
      
          prev-x = start-x + total-width
          prev-depth-offset = ox
          x = start-x + total-width
          let center-x = start-x + total-width / 2
      
          // Display label below channel numbers
          if label != none {
            draw-layer-label(l, label, center-x, y-offset - 0.5, size: font-sizes.layer-label)
          }
      
          // Display xlabel if provided
          if xlabel != none {
            content((center-x, y-offset - 0.8), 
              [#text(size: scaled-font(font-sizes.layer-label), xlabel)])
          }
      
          // Display ylabel and zlabel if provided
          if ylabel-val != none {
            content((start-x - 0.4, y-offset + h/2), anchor: "east",
              [#text(size: scaled-font(font-sizes.layer-label), str(ylabel-val))])
          }
          if zlabel-val != none {
            content((start-x + total-width + ox + 0.4, y-offset + h/2 + oy/2), anchor: "west",
              [#text(size: scaled-font(font-sizes.layer-label), str(zlabel-val))])
          }
      
          // Display diagonal label if provided (along bottom-right depth edge)
          if diagonal-label != none {
            let diag-start-x = start-x + total-width
            let diag-start-y = y-offset
            let diag-mid-x = diag-start-x + ox / 2.5
            let diag-mid-y = diag-start-y + oy / 2.5
            content((diag-mid-x, diag-mid-y - 0.23), angle: depth-angle-deg,
              [#text(size: scaled-font(font-sizes.channel-number), str(diagonal-label))])
          }
      
          // Track position if named
          if name != none {
            layer-positions.insert(name, (
              x: start-x, y: y-offset, w: total-width, h: h, ox: ox, oy: oy, type: "conv",
              anchors: get-layer-anchors(start-x, y-offset, total-width, h, ox, oy),
              pool-offset: 0  // Will be updated if next layer is a pool
            ))
          }
      
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0
      
          // Register legend entry
          let layer-legend = l.at("legend", default: default-legend-labels.at(l.type))
          if not legend-entries.any(e => e.key == l.type) {
            legend-entries.push((key: l.type, label: layer-legend, color: fill-color, bandfill: bandfill-color, show-relu: layer-show-relu, opacity: layer-opacity))
          }
        }
    
        // POOLING LAYER - delegates to custom with pool-specific positioning
        else if l.type == "pool" {
          let h = l.at("height", default: 4)
          let d = l.at("depth", default: 4)
          l.insert("height", h)
          l.insert("depth", d)
          let w = 0.1
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.pool)
          let layer-opacity = l.at("opacity", default: 0.75)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let label = l.at("label", default: none)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)
          // pool and unpool position themselves from their own offset rather than
          // from the loop's gap, so `auto` is resolved here instead.
          let layer-offset = { let o = l.at("offset", default: none); if o == auto { auto-offset } else { o } }
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = prev-center-y - h / 2 - oy / 2
          let pool-x = if layer-offset != none { x + layer-offset } else { x + prev-depth-offset / 2 - ox / 2 }
      
          if img == "default" {
            img = image("bird.jpg")
          }
      
          box-3d(pool-x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)
      
          draw-channels-labels(channels, pool-x + w/2, pool-x + w, y-offset, ox, oy)
      
          if label != none {
            draw-layer-label(l, label, pool-x + w/2, y-offset - 0.5)
          }
      
          if i > 0 {
            let prev-layer = layers.at(i - 1)
            let prev-name = prev-layer.at("name", default: none)
            if prev-name != none and prev-name in layer-positions {
              let prev-pos = layer-positions.at(prev-name)
              layer-positions.insert(prev-name, (
                ..prev-pos,
                pool-offset: w
              ))
            }
          }
      
          if name != none {
            layer-positions.insert(name, (
              x: pool-x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: "pool",
              anchors: get-layer-anchors(pool-x, y-offset, w, h, ox, oy),
              pool-offset: 0
            ))
          }
      
          prev-x = pool-x + w
          prev-depth-offset = ox
          if layer-offset != none {
            x += layer-offset + w
          } else {
            x = pool-x + w
          }
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0
      
          // Register legend entry
          let layer-legend = l.at("legend", default: default-legend-labels.at("pool"))
          if not legend-entries.any(e => e.key == "pool") {
            legend-entries.push((key: "pool", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }
    
        // UNPOOLING LAYER - delegates to custom with unpool-specific positioning
        else if l.type == "unpool" {
          let h = l.at("height", default: 4)
          let d = l.at("depth", default: 4)
          l.insert("height", h)
          l.insert("depth", d)
          let w = 0.1
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.unpool)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let layer-opacity = l.at("opacity", default: 0.75)
          let label = l.at("label", default: none)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)
          // pool and unpool position themselves from their own offset rather than
          // from the loop's gap, so `auto` is resolved here instead.
          let layer-offset = { let o = l.at("offset", default: none); if o == auto { auto-offset } else { o } }
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = prev-center-y - h / 2 - oy / 2
          let unpool-x = if layer-offset != none { x + layer-offset } else { x + prev-depth-offset / 2 - ox / 2 }
      
          if img == "default" {
            img = image("bird.jpg")
          }
      
          box-3d(unpool-x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)
      
          // Display channels labels
          draw-channels-labels(channels, unpool-x + w/2, unpool-x + w, y-offset, ox, oy)
      
          if label != none {
            draw-layer-label(l, label, unpool-x + w/2, y-offset - 0.5)
          }
      
          // Track position if named
          if name != none {
            layer-positions.insert(name, (
              x: unpool-x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: "unpool",
              anchors: get-layer-anchors(unpool-x, y-offset, w, h, ox, oy)
            ))
          }
      
          prev-x = unpool-x + w
          prev-depth-offset = ox
          if layer-offset != none {
            x += layer-offset + w
          } else {
            x = unpool-x + w
          }
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0
      
          // Register legend entry
          let layer-legend = l.at("legend", default: default-legend-labels.at("unpool"))
          if not legend-entries.any(e => e.key == "unpool") {
            legend-entries.push((key: "unpool", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }
    
        // DECONVOLUTIONAL LAYER - delegates to custom with deconv-specific defaults
        else if l.type == "deconv" {
          let h = l.at("height", default: 5)
          let d = l.at("depth", default: 5)
          l.insert("height", h)
          l.insert("depth", d)
          let w = l.at("width", default: 0.3)
          let label = l.at("label", default: "")
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.deconv)
          let layer-opacity = l.at("opacity", default: 0.7)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)
      
          if img == "default" {
            img = image("bird.jpg")
          }
      
          box-3d(x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)
      
          // Display channels labels
          draw-channels-labels(channels, x + w/2, x + w, y-offset, ox, oy)
      
          if label != none {
            draw-layer-label(l, label, x + w/2, y-offset - 0.5)
          }
      
          // Track position if named
          if name != none {
            layer-positions.insert(name, (
              x: x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: "deconv",
              anchors: get-layer-anchors(x, y-offset, w, h, ox, oy)
            ))
          }
      
          prev-x = x + w
          prev-depth-offset = ox
          x += w
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0
      
          // Register legend entry
          let layer-legend = l.at("legend", default: default-legend-labels.at("deconv"))
          if not legend-entries.any(e => e.key == "deconv") {
            legend-entries.push((key: "deconv", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }
    
        // CONCATENATION LAYER - delegates to custom with concat-specific defaults
        else if l.type == "concat" {
          let h = l.at("height", default: 3)
          let d = l.at("depth", default: 3)
          l.insert("height", h)
          l.insert("depth", d)
          let w = l.at("width", default: 0.15)
          let label = l.at("label", default: "")
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.concat)
          let layer-opacity = l.at("opacity", default: 0.7)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)
      
          if img == "default" {
            img = image("bird.jpg")
          }
      
          box-3d(x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)
      
          // Display channels labels
          draw-channels-labels(channels, x + w/2, x + w, y-offset, ox, oy)
      
          if label != none {
            draw-layer-label(l, label, x + w/2, y-offset - 0.5)
          }
      
          // Track position if named
          if name != none {
            layer-positions.insert(name, (
              x: x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: "concat",
              anchors: get-layer-anchors(x, y-offset, w, h, ox, oy)
            ))
          }
      
          prev-x = x + w
          prev-depth-offset = ox
          x += w
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0
      
          // Register legend entry
          let layer-legend = l.at("legend", default: default-legend-labels.at("concat"))
          if not legend-entries.any(e => e.key == "concat") {
            legend-entries.push((key: "concat", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }
    
        // GLOBAL AVERAGE POOLING - delegates to custom with gap-specific defaults
        else if l.type == "gap" {
          let h = l.at("height", default: 1.5)
          let d = l.at("depth", default: 1.5)
          l.insert("height", h)
          l.insert("depth", d)
          let w = 0.3
          let label = l.at("label", default: "")
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.gap)
          let layer-opacity = l.at("opacity", default: 0.7)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)
      
          if img == "default" {
            img = image("bird.jpg")
          }
      
          box-3d(x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)
      
          // Display channels labels
          draw-channels-labels(channels, x + w/2, x + w, y-offset, ox, oy)
      
          if label != none {
            draw-layer-label(l, label, x + w/2, y-offset - 0.5)
          }
      
          // Track position if named
          if name != none {
            layer-positions.insert(name, (
              x: x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: "gap",
              anchors: get-layer-anchors(x, y-offset, w, h, ox, oy)
            ))
          }
      
          prev-x = x + w
          prev-depth-offset = ox
          x += w
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0
      
          // Register legend entry
          let layer-legend = l.at("legend", default: default-legend-labels.at("gap"))
          if not legend-entries.any(e => e.key == "gap") {
            legend-entries.push((key: "gap", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }
    
        // FULLY CONNECTED - delegates to custom with fc-specific defaults
        else if l.type == "fc" {
          let h = l.at("height", default: 3)
          let d = l.at("depth", default: 0.4)
          l.insert("height", h)
          l.insert("depth", d)
          let w = 0.2
          let label = l.at("label", default: "")
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.fc)
          let layer-opacity = l.at("opacity", default: 0.7)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)
      
          if img == "default" {
            img = image("bird.jpg")
          }
      
          box-3d(x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)
      
          // Display channels labels
          draw-channels-labels(channels, x + w/2, x + w, y-offset, ox, oy)
      
          if label != none {
            draw-layer-label(l, label, x + w/2, y-offset - 0.5)
          }
      
          // Track position if named
          if name != none {
            layer-positions.insert(name, (
              x: x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: "fc",
              anchors: get-layer-anchors(x, y-offset, w, h, ox, oy)
            ))
          }
      
          prev-x = x + w
          prev-depth-offset = ox
          x += w
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0
      
          // Register legend entry
          let layer-legend = l.at("legend", default: default-legend-labels.at("fc"))
          if not legend-entries.any(e => e.key == "fc") {
            legend-entries.push((key: "fc", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }
    
        // SUM NODE - uses unique circle rendering (not box-based like custom)
        else if l.type == "sum" {
          let radius = l.at("radius", default: 0.4)
          let symbol = l.at("symbol", default: "+")
          let label = l.at("label", default: none)
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.sum)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let layer-opacity = l.at("opacity", default: 1.0)
          let channels = l.at("channels", default: none)
      
          // Center x accounts for depth offset of previous arrow
          let center-x = x + radius + prev-depth-offset / 2
          let center-y = arrow-axis-y

          // The sum node is an operator, not a data block, so it is drawn flat with
          // an explicit outline rather than the gradient-shaded fill used elsewhere.
          // The outline is taken from the palette instead of being derived from the
          // fill: deriving it pushes saturation on a near-neutral fill, which turns
          // a white node's ring an arbitrary hue.
          let stroke-color = l.at("stroke", default: colors.sum-stroke)
          let sum-stroke = (paint: stroke-color, thickness: strokes.solid.thickness * 1.5)
          fill-color = fill-color.transparentize((1-layer-opacity)*100%)

          circle((center-x, center-y), radius: radius,
            fill: fill-color,
            stroke: sum-stroke)

          if symbol != none {
            let symbole-size = scaled-font(font-sizes.label * 2.5)
            content((center-x, center-y),
              [#v(-0.185 * symbole-size)#text(size: symbole-size, weight: "bold", fill: stroke-color, symbol)])
          }
      
          // Display channels labels (below and optionally on diagonal)
          if channels != none {
            let (ox, oy) = get-depth-offsets(radius * 2)
            draw-channels-labels(channels, center-x, center-x + radius, center-y - radius, ox, oy)
          }
      
          // Display label below the sum node
          if label != none {
            draw-layer-label(l, label, center-x, center-y - 1.5 * radius)
          }
      
          prev-x = center-x + radius
          prev-depth-offset = 0
          x += radius * 3
      
          if name != none {
            let (ox, oy) = get-depth-offsets(radius * 2)
            layer-positions.insert(name, (
              x: x - radius * 2, y: center-y - radius, w: radius * 2, h: radius * 2, ox: ox, oy: oy,
              type: "sum", radius: radius, center-x: center-x,
              anchors: get-layer-anchors(x - radius * 2, center-y - radius, radius * 2, radius * 2, ox, oy),
              pool-offset: 0
            ))
          }
      
          prev-center-y = center-y
          prev-pool-width = 0
      
          // Register legend entry
          let layer-legend = l.at("legend", default: default-legend-labels.at("sum"))
          if not legend-entries.any(e => e.key == "sum") {
            legend-entries.push((key: "sum", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity, stroke: stroke-color))
          }
        }
    
        // CONVOLUTIONAL SOFTMAX (Combined layer)
        else if l.type == "convsoftmax" {
          let h = l.at("height", default: 4)
          let d = l.at("depth", default: 4)
          l.insert("height", h)
          l.insert("depth", d)
          let w = l.at("width", default: 0.1)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let label = l.at("label", default: "")
          let name = l.at("name", default: none)
          let fill-color = l.at("fill", default: colors.convsoftmax)
          let layer-opacity = l.at("opacity", default: 0.5)
          let channels = l.at("channels", default: none)
          let img = l.at("image", default: none)
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)
      
          if img == "default" {
            img = image("bird.jpg")
          }
      
          box-3d(x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)
      
          // Display channels labels
          draw-channels-labels(channels, x + w/2, x + w, y-offset, ox, oy)
      
          if label != none {
            draw-layer-label(l, label, x + w/2, y-offset - 0.5)
          }
      
          // Track position if named
          if name != none {
            layer-positions.insert(name, (
              x: x, y: y-offset, w: w, h: h, ox: ox, oy: oy,
              anchors: get-layer-anchors(x, y-offset, w, h, ox, oy)
            ))
          }
      
          prev-x = x + w
          prev-depth-offset = ox
          x += w
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0
      
          // Register legend entry
          let layer-legend = l.at("legend", default: default-legend-labels.at("convsoftmax"))
          if not legend-entries.any(e => e.key == "convsoftmax") {
            legend-entries.push((key: "convsoftmax", label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }
    
        // SOFTMAX / OUTPUT - delegates to custom with softmax/output-specific defaults
        else if l.type == "softmax" or l.type == "output" {
          let h = l.at("height", default: 3)
          let d = l.at("depth", default: 0.4)
          l.insert("height", h)
          l.insert("depth", d)
          let w = 0.2
          let label = l.at("label", default: if l.type == "softmax" { "Softmax" } else { "Output" })
          let name = l.at("name", default: none)
          let layer-show-connection = l.at("show-connection", default: true)
          let connection-label = l.at("connection-label", default: none)
          let classes = l.at("classes", default: none)
          let channels = l.at("channels", default: none)
          let fill-color = l.at("fill", default: if l.type == "softmax" { colors.softmax } else { colors.output })
          let layer-opacity = l.at("opacity", default: 0.5)
          let img = l.at("image", default: none)
          let (ox, oy) = get-depth-offsets(d)
          let y-offset = get-y-offset-for-center-on-axis(h, d, arrow-axis-y)
      
          if img == "default" {
            img = image("bird.jpg")
          }
      
          box-3d(x, y-offset, w, h, d, fill-color, opacity: layer-opacity, show-left: true, show-right: true, image: img)
      
          // Display channels labels (preferred over classes)
          if channels != none {
            draw-channels-labels(channels, x + w/2, x + w, y-offset, ox, oy)
          } else if classes != none {
            content((x + w/2, y-offset - 0.3), 
              [#text(size: scaled-font(font-sizes.output-number), str(classes))])
          }
          if label != none {
            draw-layer-label(l, label, x + w/2, y-offset - 0.6)
          }
      
          // Track position if named
          if name != none {
            layer-positions.insert(name, (
              x: x, y: y-offset, w: w, h: h, ox: ox, oy: oy, type: l.type,
              anchors: get-layer-anchors(x, y-offset, w, h, ox, oy)
            ))
          }
      
          prev-x = x + w
          prev-depth-offset = ox
          x += w
          prev-center-y = get-perspective-center-y(y-offset, h, oy)
          prev-pool-width = 0
      
          // Register legend entry
          let layer-legend = l.at("legend", default: default-legend-labels.at(l.type))
          if not legend-entries.any(e => e.key == l.type) {
            legend-entries.push((key: l.type, label: layer-legend, color: fill-color, bandfill: fill-color, show-relu: false, opacity: layer-opacity))
          }
        }

        // A repeated block, drawn as ghosted copies stacked behind the real one.
        //
        // Depth-scaled models fake repetition today by stuffing extra entries into
        // `widths`, which is a visual coincidence: the package cannot label the
        // repeat, bracket it, or reflect it anywhere. Declaring it makes the count
        // part of the figure's meaning rather than of its geometry.
        //
        // The width is recovered from how far the drawing cursor moved, so this
        // works for any layer type without each one having to report its own size.
        let repeat-n = if l.type in ("pool", "unpool", "sum") { 1 } else { l.at("repeat", default: 1) }
        if repeat-n > 1 {
          let rw = x - repeat-x0
          if rw > 0 {
            let rh = l.at("height", default: 5)
            let rd = l.at("depth", default: 5)
            let (rox, roy) = get-depth-offsets(rd)
            let ry = get-y-offset-for-center-on-axis(rh, rd, arrow-axis-y)
            // Above the block: below it collides with the layer label, and the space
            // over the top face is otherwise unused. The count sits above the left
            // end rather than centred, so it reads as an annotation on the bracket
            // rather than as a stray number over the block.
            // Spans the top face, so the bracket sits directly over the face it
            // describes rather than reaching down to the front-left corner.
            let bx0 = repeat-x0 + rox
            let bx1 = repeat-x0 + rw + rox
            let by = ry + rh + roy + 0.26
            let rule = (paint: colors.connection, thickness: strokes.connection.thickness, cap: "butt", join: "miter")
            line((bx0, by - 0.16), (bx0, by), (bx1, by), (bx1, by - 0.16), stroke: rule)
            content((bx0, by + 0.12), anchor: "base-west",
              [#text(size: scaled-font(font-sizes.channel-number), weight: "bold", "x" + str(repeat-n))])
          }
        }
      }
    }

    (
      body: body,
      positions: layer-positions,
      segments: arrow-segments,
      legend: legend-entries,
      max-half-extent: max-half-extent,
      prev-x: prev-x,
      prev-depth-offset: prev-depth-offset,
      prev-center-y: prev-center-y,
      first-west: first-west,
      end-x: x,
    )
  }

  let trunk = walk-trunk(layers, 0, arrow-axis-y)
  trunk.body
  let layer-positions = trunk.positions
  let arrow-segments = trunk.segments
  let legend-entries = trunk.legend
  let max-half-extent = trunk.max-half-extent
  let prev-x = trunk.prev-x
  let prev-depth-offset = trunk.prev-depth-offset
  
  // After all layers are drawn, calculate arrow segment midpoints for ALL named layer pairs
  // This ensures skip connections between non-consecutive layers can find their anchor points
  for (i, l) in layers.enumerate() {
    let curr-name = l.at("name", default: none)
    if curr-name != none and curr-name in layer-positions {
      // Find the previous named layer (skip over unnamed layers like pool/unpool)
      let prev-name = none
      for j in range(i - 1, -1, step: -1) {
        let candidate-name = layers.at(j).at("name", default: none)
        if candidate-name != none and candidate-name in layer-positions {
          prev-name = candidate-name
          break
        }
      }
      
      // If we found a previous named layer, calculate the arrow segment
      if prev-name != none {
        let prev-pos = layer-positions.at(prev-name)
        let curr-pos = layer-positions.at(curr-name)
        
        // Use true_east and add pool-offset if there's a pool after the previous layer
        let pool-offset = prev-pos.at("pool-offset", default: 0)
        let arrow-start = (prev-pos.anchors.true_east.at(0) + pool-offset, prev-pos.anchors.true_east.at(1))
        let arrow-end = curr-pos.anchors.true_west
        
        // Calculate midpoint of the arrow segment
        let mid-x = (arrow-start.at(0) + arrow-end.at(0)) / 2
        let mid-y = arrow-start.at(1)
        
        // Store for skip connections - these will override any stored during drawing
        arrow-segments.insert(prev-name + "-out", (
          start: arrow-start,
          mid: (mid-x, mid-y),
          x: mid-x,
          y: mid-y
        ))
        arrow-segments.insert(curr-name + "-in", (
          end: arrow-end,
          mid: (mid-x, mid-y),
          x: mid-x,
          y: mid-y
        ))
      }
    }
  }
  
  // Lane assignment for connections that ask for `pos: auto`.
  //
  // A route drawn over the stack needs its own height, and picking those by
  // hand means every one shifts when a connection is added. Sorting by where a
  // route starts and giving it the lowest lane whose previous occupant has
  // already finished is the usual interval-packing greedy: routes that do not
  // overlap share a lane instead of each claiming a new one.
  // Lane height for connections that ask for `pos: auto`.
  //
  // Height carries meaning rather than falling out of sort order: a route is
  // raised one lane-unit for each extra block it reaches over. The shortest
  // possible skip, one block, sits closest to the stack; a two-block skip is one
  // unit above it, and so on. Routes of equal reach share a height, so a figure
  // reads consistently, and a longer route arcs over a shorter one rather than
  // crossing it.
  let lane-clearance = 0.7   // from the tallest layer to the shortest route
  // Positions along the trunk, for ranking routes by how far they reach.
  //
  // Layers inside a branch are indexed at the branch's own position: a branch
  // occupies one slot on the trunk however deep it is, and a route reaching into
  // one has travelled as far as the branch, not as far as some position within
  // it. Without this a connection targeting a branch layer was not found at all,
  // so it fell back to lane 0, and every such route shared one lane and drew on
  // top of the others.
  let collect-index(ls, base) = {
    let m = (:)
    for (i, l) in ls.enumerate() {
      let at = if base == none { i } else { base }
      let n = l.at("name", default: none)
      if n != none { m.insert(n, at) }
      if l.type == "branch" {
        for sub in l.at("branches", default: ()) {
          for (k, v) in collect-index(sub, at) { m.insert(k, v) }
        }
      }
    }
    m
  }
  let layer-index = collect-index(layers, none)
  let auto-lane = (:)
  let entries = ()
  for (i, conn) in connections.enumerate() {
    if conn.at("pos", default: 1.25) != auto { continue }
    let f = conn.at("from")
    let t = conn.at("to")
    if f not in layer-index or t not in layer-index { continue }
    if f not in layer-positions or t not in layer-positions { continue }
    let a = layer-positions.at(f)
    let b = layer-positions.at(t)
    entries.push((
      i: i,
      reach: calc.abs(layer-index.at(t) - layer-index.at(f)),
      start: calc.min(a.x, b.x),
      end: calc.max(a.x + a.w, b.x + b.w),
    ))
  }
  // Rank by reach rather than using it directly, so that one long route among
  // short ones does not leave a stack of empty lanes below it.
  //
  // Routes of equal reach share a height. Two that overlap would then be drawn
  // as one line, so the second goes to the opposite side of the axis at the same
  // height rather than being stacked above the first. Only a third overlapping
  // route of the same reach needs a new height.
  let auto-side = (:)
  let distinct = entries.map(e => e.reach).dedup().sorted()
  let offset = 0
  for r in distinct {
    // Routes of equal reach normally share a height. Two that overlap would
    // then be drawn as one line, so within a reach they are packed into
    // sub-lanes by the usual sort-by-start greedy. Equal reach still reads as a
    // group, and a longer route still sits above a shorter one.
    let group = entries.filter(e => e.reach == r).sorted(key: e => e.start)
    let lane-ends = ()
    for e in group {
      let placed = false
      for (li, le) in lane-ends.enumerate() {
        if not placed and e.start > le {
          lane-ends.at(li) = e.end
          auto-lane.insert(str(e.i), offset + int(li / 2))
          auto-side.insert(str(e.i), if calc.rem(li, 2) == 0 { "air" } else { "flat" })
          placed = true
        }
      }
      if not placed {
        lane-ends.push(e.end)
        let li = lane-ends.len() - 1
        auto-lane.insert(str(e.i), offset + int(li / 2))
        auto-side.insert(str(e.i), if calc.rem(li, 2) == 0 { "air" } else { "flat" })
      }
    }
    offset += int((lane-ends.len() + 1) / 2)
  }

  // Even spacing for connections asking for `arrive-offset: auto`.
  //
  // Routes are grouped by the edge they land on, which is the target layer plus
  // the routing mode, then spread across that edge. k routes divide it into
  // k + 1 intervals and sit at the interior boundaries, so the outermost pair is
  // inset by one gap rather than sitting on the corners. Adding a route respaces
  // the rest instead of needing every offset re-picked by hand.
  //
  // Sorted by where each route starts, so a fan-in does not cross itself.
  let auto-arrive = (:)
  {
    let groups = (:)
    for (i, conn) in connections.enumerate() {
      if conn.at("arrive-offset", default: 0) != auto { continue }
      if not conn.at("touch-layer", default: false) { continue }
      let f = conn.at("from")
      let t = conn.at("to")
      if f not in layer-positions or t not in layer-positions { continue }
      let key = t + "/" + conn.at("mode", default: "air")
      let entry = (i: i, x: layer-positions.at(f).x)
      groups.insert(key, groups.at(key, default: ()) + (entry,))
    }
    for (key, members) in groups {
      let t = key.split("/").at(0)
      let mode = key.split("/").at(1)
      let tp = layer-positions.at(t)
      // The arrival edge: the west side's top and bottom edges run along the
      // isometric depth direction, the left edge along the layer's height.
      let edge = if mode == "depth" { tp.h } else {
        calc.sqrt(tp.ox * tp.ox + tp.oy * tp.oy)
      }
      let ordered = members.sorted(key: m => m.x)
      let k = ordered.len()
      for (j, m) in ordered.enumerate() {
        auto-arrive.insert(str(m.i), edge * ((j + 1) / (k + 1) - 0.5))
      }
    }
  }

  // Axis arrowheads that a connection attaches to. A route is drawn after the
  // axis, so its stroke lands across the arrowhead it departs from or arrives
  // at, showing as a coloured sliver through the head. Redrawing just those
  // heads afterwards restores them without disturbing the draw order of
  // anything else.
  let anchored-heads = ()
  // Lowest point any route reaches, so group brackets can sit clear of routes
  // that run beneath the stack rather than colliding with them.
  let lowest-route-y = arrow-axis-y

  // The main axis flow gets a legend entry of its own when named. Without it a
  // legend can explain every skip in a figure and say nothing about the arrows
  // carrying the actual forward pass.
  if main-legend != none {
    legend-entries.push((
      key: "main-flow", label: main-legend, kind: "line",
      color: colors.connection, bandfill: colors.connection,
      style: (paint: colors.connection, thickness: strokes.connection.thickness, dash: none),
      show-relu: false, opacity: 1.0,
    ))
  }

  for (conn-index, conn) in connections.enumerate() {
    let from-name = conn.at("from")
    let to-name = conn.at("to")
    let conn-type = conn.at("type", default: "skip")
    // Routes run over the top of the stack by default. That is the convention in
    // PlotNeuralNet and in most published diagrams, and it is the house style
    // here. "flat" routes underneath, "depth" along the projection.
    let conn-mode = conn.at("mode", default: auto-side.at(str(conn-index), default: "air"))
    let conn-pos = conn.at("pos", default: 1.25)
    if conn-pos == auto {
      let lane = auto-lane.at(str(conn-index), default: 0)
      conn-pos = max-half-extent + conn.at("clearance", default: lane-clearance) + lane * lane-unit
    }
    let conn-label = conn.at("label", default: none)
    let conn-opacity = conn.at("opacity", default: 0.7)
    let touch-layer = conn.at("touch-layer", default: false)
    // Per-connection stroke. Residual adds, concat feeds, attention routes and
    // auxiliary supervision are different things and should look different.
    // `thickness` multiplies the palette width rather than replacing it, so a
    // figure passing stroke-thickness to draw-network still scales its
    // connections. Arrowheads take the line colour.
    let conn-style = (
      paint: conn.at("color", default: colors.connection),
      thickness: strokes.connection.thickness * conn.at("thickness", default: 1),
      dash: conn.at("dash", default: none),
    )
    
    // A named connection style gets a legend entry drawn as a line sample rather
    // than a colour swatch, since what distinguishes it is stroke, not fill.
    let conn-legend = conn.at("legend", default: none)
    if conn-legend != none {
      let legend-key = "conn-" + str(conn-legend)
      if not legend-entries.any(e => e.key == legend-key) {
        legend-entries.push((
          key: legend-key, label: conn-legend, kind: "line",
          color: conn-style.paint, bandfill: conn-style.paint,
          style: conn-style, show-relu: false, opacity: 1.0,
        ))
      }
    }

    if from-name in layer-positions and to-name in layer-positions {
      let from-pos = layer-positions.at(from-name)
      let to-pos = layer-positions.at(to-name)
      
      // Use arrow segment midpoints if available, otherwise fall back to layer edges
      let from-anchor-key = from-name + "-out"
      let to-anchor-key = to-name + "-in"
      
      // Check if the from layer has a pool attached but we're not departing from the pool itself
      let from-has-pool = from-pos.at("pool-offset", default: 0) > 0
      let from-type = from-pos.at("type", default: none)
      let departing-from-layer-with-pool = from-has-pool and from-type != "pool"
      
      // Use true midpoint of arrow segment after from layer (uses stored start point)
      let from-anchor = if departing-from-layer-with-pool {
        // Special case: departing from a layer with attached pool (but not the pool itself)
        // Use specific edges of the east side based on connection mode
        let base-x = from-pos.x + from-pos.w
        let base-y = from-pos.y
        let h = from-pos.h
        let ox = from-pos.ox
        let oy = from-pos.oy
        
        if conn-mode == "air" {
          // Middle of top diagonal edge of east side
          (base-x + ox/2, base-y + h + oy/2)
        } else if conn-mode == "depth" {
          // Middle of left edge of east side
          (base-x, base-y + h/2 + oy/2)
        } else {
          // "flat" - Middle of bottom edge of east side
          (base-x + ox/2, base-y + oy/2)
        }
      } else if from-anchor-key in arrow-segments {
        anchored-heads.push(from-anchor-key)
        let seg = arrow-segments.at(from-anchor-key)
        // Use the arrow's actual start point for x (depth-adjusted)
        (seg.mid.at(0), seg.mid.at(1))
      } else {
        from-pos.anchors.true_east
      }
      
      // Determine target anchor point
      let to-type = to-pos.at("type", default: none)
      // Arrival point on the target layer.
      //
      // `touch-layer` already picks a side from the routing mode: air arrives on
      // the top edge, flat on the bottom, depth on the left. `arrive-offset`
      // spreads along that same edge, so several routes can fan into one layer
      // without inventing a second vocabulary for something the mode already
      // says. The offset runs along the edge rather than in x, because the top
      // and bottom edges of the west side follow the isometric depth direction.
      let arrive-off-raw = conn.at("arrive-offset", default: 0)
      let arrive-off = if arrive-off-raw == auto {
        auto-arrive.at(str(conn-index), default: 0)
      } else { arrive-off-raw }
      let to-anchor = if touch-layer {
        // Special case: arrive at specific edge of west side of destination layer
        let base-x = to-pos.x
        let base-y = to-pos.y
        let h = to-pos.h
        let ox = to-pos.ox
        let oy = to-pos.oy
        
        let diag = calc.max(calc.sqrt(ox * ox + oy * oy), 0.0001)
        if conn-mode == "air" {
          // Top diagonal edge of the west side, offset along it
          (base-x + ox/2 + arrive-off * ox / diag, base-y + h + oy/2 + arrive-off * oy / diag)
        } else if conn-mode == "depth" {
          // Left edge of the west side, offset vertically
          (base-x, base-y + h/2 + oy/2 + arrive-off)
        } else {
          // "flat" - bottom diagonal edge of the west side, offset along it
          (base-x + ox/2 + arrive-off * ox / diag, base-y + oy/2 + arrive-off * oy / diag)
        }
      } else if to-type == "sum" {
        // For sum layers, use the stored center-x (which already accounts for depth offset)
        let center-x = to-pos.center-x
        let center-y = to-pos.y + to-pos.radius
        let center = (center-x, center-y)
        let radius = to-pos.at("radius", default: 0.4)
        if conn-mode == "flat" {
          (center.at(0), center.at(1) - radius)
        } else if conn-mode == "air" {
          (center.at(0), center.at(1) + radius)
        } else if conn-mode == "depth" {
          let angle = 225 * calc.pi / 180
          (center.at(0) + radius * calc.cos(angle), center.at(1) + radius * calc.sin(angle))
        } else {
          (center.at(0), center.at(1) - radius)
        }
      } else if to-anchor-key in arrow-segments {
        anchored-heads.push(to-anchor-key)
        let seg = arrow-segments.at(to-anchor-key)
        // Use the arrow's midpoint (both x and y)
        seg.mid
      } else {
        to-pos.anchors.true_west
      }
      
      if conn-type == "skip" {
        let conn-layers = conn.at("layers", default: none)
        
        if conn-mode == "flat" {
          let down-y = from-anchor.at(1) - conn-pos
          lowest-route-y = calc.min(lowest-route-y, down-y)
          let waypoint1 = (from-anchor.at(0), down-y)
          let waypoint2 = (to-anchor.at(0), down-y)
          
          draw-connection-path(((from-anchor, waypoint1), (waypoint1, waypoint2), (waypoint2, to-anchor)), opacity: conn-opacity, layers: conn-layers, layer-positions-ref: layer-positions, show-relu: show-relu, style: conn-style, tail-behind: touch-layer and conn-mode != "air")
          
          if conn-label != none {
            content(((waypoint1.at(0) + waypoint2.at(0)) / 2, down-y - 0.3), 
              [#text(size: scaled-font(font-sizes.layer-label), conn-label)])
          }
        } else if conn-mode == "depth" {
          let (ox, oy) = get-depth-offsets(conn-pos * 2.5)
          let waypoint1 = (from-anchor.at(0) - ox, from-anchor.at(1) - oy)
          lowest-route-y = calc.min(lowest-route-y, waypoint1.at(1))
          // For sum circles, adjust waypoint2 x-coordinate to account for south-west arrival
          let waypoint2-x = if to-type == "sum" {
            // Compensate for the south-west arrival offset (radius * cos(225°))
            let radius = to-pos.at("radius", default: 0.4)
            let angle = 225 * calc.pi / 180
            to-anchor.at(0) - ox - radius * calc.cos(angle)
          } else {
            to-anchor.at(0) - ox
          }
          let waypoint2 = (waypoint2-x, from-anchor.at(1) - oy)
          
          draw-connection-path(((from-anchor, waypoint1), (waypoint1, waypoint2), (waypoint2, to-anchor)), opacity: conn-opacity, layers: conn-layers, layer-positions-ref: layer-positions, show-relu: show-relu, style: conn-style, tail-behind: touch-layer and conn-mode != "air")
          
          if conn-label != none {
            content(((waypoint1.at(0) + waypoint2.at(0)) / 2, waypoint1.at(1) - 0.3), 
              [#text(size: scaled-font(font-sizes.layer-label), conn-label)])
          }
        } else if conn-mode == "air" {
          let up-y = arrow-axis-y + conn-pos
          let down-y = from-anchor.at(1) - conn-pos
          let waypoint1 = (from-anchor.at(0), up-y)
          let waypoint2 = (to-anchor.at(0), up-y)
          
          draw-connection-path(((from-anchor, waypoint1), (waypoint1, waypoint2), (waypoint2, to-anchor)), opacity: conn-opacity, layers: conn-layers, layer-positions-ref: layer-positions, show-relu: show-relu, style: conn-style, tail-behind: touch-layer and conn-mode != "air")
          
          if conn-label != none {
            content(((waypoint1.at(0) + waypoint2.at(0)) / 2, up-y + 0.28), 
              [#text(size: scaled-font(font-sizes.layer-label), conn-label)])
          }
        }
      }
    }
  }

  for key in anchored-heads.dedup() {
    let seg = arrow-segments.at(key)
    let (mx, my) = seg.mid
    // The axis runs left to right, so a unit span through the midpoint
    // reproduces the head's position and direction.
    draw-arrow-icon(mx - 0.5, my, mx + 0.5, my, opacity: 0.7)
  }
  
  // Group brackets. Backbone, neck and head are the phrases anyone uses to
  // explain one of these figures, and until now there was no way to draw them.
  //
  // A square bracket rather than a brace: everything else in the package is
  // drawn with flat edges, and a curly brace would be the only curve on the
  // page. The ends are inset slightly so two adjacent groups read as two rather
  // than running into one continuous rule.
  if groups.len() > 0 {
    let group-tick = 0.22
    let group-inset = 0.12
    for g in groups {
      let f = g.at("from")
      let t = g.at("to")
      if f not in layer-positions or t not in layer-positions { continue }
      let a = layer-positions.at(f)
      let b = layer-positions.at(t)
      // Span the drawn footprint, which leans right of the front face by the
      // isometric shear, not just the front faces.
      let x0 = calc.min(a.x, b.x) + group-inset
      let x1 = calc.max(a.x + a.w + a.ox, b.x + b.w + b.ox) - group-inset
      let y = calc.min(arrow-axis-y - max-half-extent, lowest-route-y) - g.at("offset", default: 1.15)
      let paint = g.at("color", default: colors.connection)
      line((x0, y + group-tick), (x0, y), (x1, y), (x1, y + group-tick),
        stroke: (paint: paint, thickness: strokes.connection.thickness, cap: "butt", join: "miter"))
      let label = g.at("label", default: none)
      if label != none {
        content(((x0 + x1) / 2, y - 0.34),
          [#text(size: scaled-font(font-sizes.label), weight: "bold", fill: paint, label)])
      }
    }
  }

  if show-legend {
    // Position legend after the last layer, accounting for its width and depth
    let legend-x = prev-x + prev-depth-offset + 1.0
    let legend-item-height = 0.4
    let legend-box-size = 0.3
    
    // Count total legend entries to calculate vertical centering
    let entry-count = legend-entries.len()
    
    // Calculate total legend height: title + spacing + (entries * item-height)
    let legend-total-height = 0.5 + entry-count * legend-item-height
    
    // Center legend vertically around arrow-axis-y
    let legend-y = arrow-axis-y + legend-total-height / 2
    
    content((legend-x - 0.05, legend-y + 0.15),
      anchor: "north-west",
      [#text(size: scaled-font(font-sizes.legend-title), weight: "bold", legend-title)])
    
    legend-y -= 0.6
    
    // A stroke sample needs more width than a colour swatch, or a dash pattern
    // has no room to read. Widen the whole sample column when any line entry is
    // present, so the labels stay on one edge.
    let has-line = legend-entries.any(e => e.at("kind", default: "box") == "line")
    let sample-width = if has-line { legend-box-size * 2.4 } else { legend-box-size }

    // Render all legend entries in order of appearance
    for entry in legend-entries {
      // An entry may carry an explicit outline; otherwise derive one from its fill.
      let item-stroke = dynamic-color-strokes(entry.color)
      if entry.at("stroke", default: none) != none {
        item-stroke.solid.paint = entry.stroke
      }
      let alpha = 100% - entry.at("opacity", default: 1.0) * 100%
      
      if entry.at("kind", default: "box") == "line" {
        // A sample of the actual stroke, with a head, so dash and weight read at
        // a glance the way they do in the figure.
        let mid-y = legend-y + legend-box-size / 2
        // Stop the line at the back plane of the head rather than running it to
        // the tip. The head is concave behind its widest point, so a line ending
        // any further forward shows its end cap inside that notch, which is most
        // obvious on a thick stroke. Ending at the barbs puts the line end under
        // the widest part of the head, where it is covered.
        let head-size = arrow-config.triangle-size
        let head-center = legend-x + sample-width - head-size * 0.9
        line((legend-x, mid-y), (head-center - head-size * 0.75, mid-y),
          stroke: (paint: entry.style.paint, thickness: entry.style.thickness,
                   dash: entry.style.dash, cap: "butt"))
        draw-arrow-icon(head-center - 0.5, mid-y, head-center + 0.5, mid-y,
          paint: entry.style.paint)
      } else if entry.at("show-relu", default: false) {
        // Draw split rectangle: 2/3 fill color (left), 1/3 bandfill color (right)
        let split-x = legend-x + sample-width * 2 / 3
        rect((legend-x, legend-y), (split-x, legend-y + legend-box-size),
          fill: entry.color.transparentize(alpha), stroke: none)
        rect((split-x, legend-y), (legend-x + sample-width, legend-y + legend-box-size),
          fill: entry.bandfill.transparentize(alpha), stroke: none)
        // Draw outline
        rect((legend-x, legend-y), (legend-x + sample-width, legend-y + legend-box-size),
          fill: none, stroke: item-stroke.solid)
      } else {
        // Draw solid rectangle
        rect((legend-x, legend-y), (legend-x + sample-width, legend-y + legend-box-size),
          fill: entry.color.transparentize(alpha), stroke: item-stroke.solid)
      }
      
      content((legend-x + sample-width + 0.2, legend-y - 0.013 + legend-box-size / 2), anchor: "west",
        [#text(size: scaled-font(font-sizes.legend-item), entry.label)])
      
      legend-y -= legend-item-height
    }
  }
})}
#import "../../src/lib.typ": draw-network

#set page(width: auto, height: auto, margin: 6mm)
#set text(font: "Libertinus Serif", size: 10pt)

// Four ways to fuse two feature maps.
//
// The whole-network figures in this folder answer where fusion happens. This
// one answers what the fusion block actually contains, since "mid fusion" names
// a position in the network and not an operator, and the operators behave very
// differently.
//
// Each diagram takes the same two inputs, a visible feature map and a thermal
// one at the same resolution and channel count, and returns one fused map of
// the stock width. What changes is the middle.

#let rgb-in = (type: "input", width: 0.35, height: 2.6, depth: 1.6, label: "F_RGB",
  channels: (128, 80), fill: rgb("#466A9F"), opacity: 0.85, show-connection: true, label-orient: "horizontal")
#let ir-in = (type: "input", width: 0.35, height: 2.6, depth: 1.6, label: "F_IR",
  channels: (128, 80), fill: rgb("#CC2E40"), opacity: 0.85, show-connection: true, label-orient: "horizontal")
#let fused = (type: "output", width: 0.35, height: 2.6, depth: 1.6, label: "F_fused",
  channels: (128, 80), name: "out", offset: 1.8, label-orient: "horizontal")

#let mix(l, w: 0.4, h: 2.6, d: 1.6, ..rest) = (type: "custom", width: w, height: h, depth: d,
  label: l, fill: rgb("#73000A"), opacity: 0.9, label-orient: "horizontal", ..rest.named())

#let aux(l, w: 0.3, h: 1.4, d: 1.0, ..rest) = (type: "custom", width: w, height: h, depth: d,
  label: l, fill: rgb("#65780B"), opacity: 0.9, label-orient: "horizontal", ..rest.named())

#let caption(n, title, note) = [
  #v(3mm)
  #block(width: 155mm, text(weight: "bold")[#n. #title]) \
  #block(width: 155mm, text(size: 9pt, fill: rgb("#5C5C5C"))[#note])
  #v(1mm)
]

// ---------------------------------------------------------------------------
#caption(1)[Concatenation and pointwise mix][
  The default. Stacks the channels and lets a $1 times 1$ convolution learn the
  recipe. Expressive, but the recipe is fixed once training ends, and the
  concatenation doubles the width before folding it back.
]

#draw-network((
  (type: "branch", spread: 6, lead: 1.6, branches: ((rgb-in,), (ir-in,))),
  (type: "concat", width: 0.5, height: 2.9, depth: 1.8, label: "concat", channels: (256, 80),
    name: "cat", offset: 1.6, label-orient: "horizontal"),
  mix("1×1", channels: (128, 80), name: "m", offset: 1.6),
  fused,
))

// ---------------------------------------------------------------------------
#caption(2)[Illumination-gated sum][
  A subnetwork reads the frame and emits a two-way softmax, so the mixture
  varies with the lighting rather than with the dataset average. The sum keeps
  the channel count, so nothing folds back, but it can only reweight the two
  streams and never recombine their channels.
]

#draw-network((
  (type: "branch", spread: 7, lead: 1.6, branches: (
    (rgb-in,),
    (aux("illum net", w: 0.35, h: 1.6, d: 1.1, channels: (2,), name: "g", show-relu: false),),
    (ir-in,),
  )),
  (type: "sum", label: "w_R·F_R + w_I·F_I", radius: 0.4, stroke: rgb("#73000A"),
    name: "s", offset: 1.8, label-orient: "horizontal"),
  fused,
))

// ---------------------------------------------------------------------------
#caption(3)[Channel-attention on the concatenation][
  Squeeze-and-excitation applied to the stacked map. A global descriptor scores
  every channel of the concatenation, and the scores scale it before the mix, so
  the network can suppress whole channels of whichever modality is unhelpful on
  this frame. Halfway between the first two: input-dependent like the gate, but
  per channel rather than per modality.
]

#draw-network((
  (type: "branch", spread: 6, lead: 1.6, branches: ((rgb-in,), (ir-in,))),
  (type: "concat", width: 0.5, height: 2.9, depth: 1.8, label: "concat", channels: (256, 80),
    name: "cat", offset: 1.6, label-orient: "horizontal"),
  (type: "branch", spread: 5, lead: 2.8, rejoin-lead: 2.6, branches: (
    (aux("GAP → FC → σ", w: 0.3, h: 1.3, d: 0.9, channels: (256,), name: "se", offset: 1.4, show-relu: false),),
    ((type: "custom", width: 0.25, height: 2.2, depth: 1.4, label: "identity", channels: (256, 80),
      fill: rgb("#C7C7C7"), opacity: 0.9, show-relu: false, name: "id", offset: 1.4, label-orient: "horizontal"),),
  )),
  (type: "sum", symbol: "x", label: "scale", radius: 0.4, stroke: rgb("#73000A"),
    name: "sc", offset: 1.6, label-orient: "horizontal"),
  mix("1×1", channels: (128, 80), name: "m", offset: 1.6),
  fused,
))

// ---------------------------------------------------------------------------
#caption(4)[Cross-modality attention][
  Each stream queries the other. The visible branch takes its queries from
  F_RGB and its keys and values from F_IR, the thermal branch does the reverse,
  and each result is added back to the stream it came from before the two meet.
  The exchange is what the labels record; drawing it as arrows would put both
  crossings in one corridor, since the two branches sit at the same depth.
]

#draw-network((
  (type: "branch", spread: 7, lead: 1.6, rejoin-lead: 1.8, branches: (
    (rgb-in,
     (type: "custom", width: 0.4, height: 2.4, depth: 1.5, label: "MHA (Q from RGB)", channels: (128, 80),
       fill: rgb("#1F414D"), opacity: 0.9, name: "ar", offset: 1.6, label-orient: "horizontal"),
     (type: "sum", label: "+ F_RGB", radius: 0.34, stroke: rgb("#466A9F"), name: "sr", offset: 1.6, label-orient: "horizontal")),
    (ir-in,
     (type: "custom", width: 0.4, height: 2.4, depth: 1.5, label: "MHA (Q from IR)", channels: (128, 80),
       fill: rgb("#1F414D"), opacity: 0.9, name: "ai", offset: 1.6, label-orient: "horizontal"),
     (type: "sum", label: "+ F_IR", radius: 0.34, stroke: rgb("#CC2E40"), name: "si", offset: 1.6, label-orient: "horizontal")),
  )),
  (type: "concat", width: 0.5, height: 2.9, depth: 1.8, label: "concat", channels: (256, 80),
    name: "cat", offset: 1.6, label-orient: "horizontal"),
  mix("1×1", channels: (128, 80), name: "m", offset: 1.6),
  fused,
))

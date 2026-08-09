#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// A whole figure recoloured to one scheme
#let garnet = rgb("#73000A")
#let atlantic = rgb("#466A9F")
#let honeycomb = rgb("#A49137")

#draw-network(
  (
    conv(label: "stem", fill: atlantic, legend: "convolution"),
    conv(label: "stage", fill: atlantic, widths: (0.4, 0.4)),
    pool(fill: honeycomb, legend: "pool"),
    conv(label: "stage", fill: atlantic, widths: (0.4, 0.4)),
    fc(label: "head", fill: garnet, depth: 0, legend: "head"),
  ),
  show-legend: true,
)

#import "../../src/lib.typ": *
#set page(width: auto, height: auto, margin: 3mm)
// @show
// Any content works, not only an image
#draw-network((
  custom(image: [#text(size: 20pt)[$Sigma$]], width: 0.3, height: 4, depth: 4),
  custom(image: [hello], width: 0.3, height: 4, depth: 4),
))

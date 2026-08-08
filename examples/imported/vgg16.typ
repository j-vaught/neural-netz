#import "../../src/lib.typ": draw-network, from-shapes, groups-from-shapes

#set page(width: auto, height: auto, margin: 5mm)

// VGG-16, imported from the pretrained torchvision checkpoint.
//
//   uv run tools/import_model.py --torchvision vgg16 --weights DEFAULT \
//       --collapse -o vgg16.json
//
// `--collapse` folds a run of identical adjacent layers into one block with a
// repeat count, which is what turns thirteen convolutions into five stages. It
// is the right default for a VGG precisely because the repetition is the point:
// three 512-channel convolutions at 28x28 are one idea applied three times, and
// drawing them three times says only that someone counted.
//
// Labels run diagonally because `offset: auto` spaces blocks by their geometry
// and knows nothing about how wide a word is. Imported names are long and the
// tail of a classifier is narrow, so horizontal labels collide there. That is
// what `defaults` is for: one field, applied to every layer, without giving up
// anything the import derived.
//
// Labels are the Sequential indices the model itself uses, so `features.17` in
// the drawing is `features[17]` in the code. Everything else is derived; the
// figure has no hand-set geometry at all.

#let data = json("vgg16.json")

#draw-network(
  from-shapes(data, label: "leaf", defaults: (label-orient: "diagonal")),
  groups: groups-from-shapes(data),
  show-legend: true,
  legend-title: "VGG-16 (imported)",
  main-legend: "forward pass",
  show-relu: true,
)

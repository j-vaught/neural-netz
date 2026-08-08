# Imported models

Figures in this folder are not authored. Each one is a trace of a real model,
turned into a layer list by `from-shapes`. Regenerate the JSON with:

```bash
uv run ../../tools/import_model.py --torchvision resnet18 -o resnet18.json
uv run ../../tools/import_model.py --torchvision vgg16 --weights DEFAULT --collapse -o vgg16.json
uv run ../../tools/import_model.py --torchvision vit_b_16 --weights DEFAULT --group-depth 3 -o vit_b_16.json
```

The JSON is committed so the figures build without torch installed.

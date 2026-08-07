#!/usr/bin/env bash
# Regenerate golden baseline images for the regression harness.
#
# Run this only when a rendering change is intentional and has been inspected.
# Pass example paths to re-bless a subset:
#   tests/bless.sh                                  # all examples
#   tests/bless.sh examples/networks/U-Net.typ      # one example
set -euo pipefail

cd "$(dirname "$0")/.."
PPI=150
mkdir -p tests/golden

if [ "$#" -gt 0 ]; then
  files=("$@")
else
  files=(examples/*/*.typ tests/cases/*.typ)
fi

for src in "${files[@]}"; do
  name="$(basename "${src%.typ}")"
  typst compile --root . --ppi "$PPI" --format png "$src" "tests/golden/${name}.png"
  echo "blessed ${name}"
done

echo "typst $(typst --version | awk '{print $2}') / ${#files[@]} example(s)"

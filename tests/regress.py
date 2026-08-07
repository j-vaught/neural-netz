#!/usr/bin/env python3
"""Golden-image regression harness for neural-netz.

Recompiles every bundled example against the working tree and pixel-diffs the
result against its baseline in tests/golden/. A clean run is the operational
definition of backward compatibility: any new feature must default to v0.3
behavior, so an unexplained diff is a regression.

Usage:
    python3 tests/regress.py                 # check every example
    python3 tests/regress.py U-Net AlexNet   # check a subset by name

Exit status is 0 when every example matches, 1 otherwise.
Re-baseline intentional changes with tests/bless.sh.
"""

import pathlib
import subprocess
import sys

from PIL import Image, ImageChops

PPI = "150"
ROOT = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = ROOT / "tests" / "golden"
CURRENT = ROOT / "tests" / "current"


def examples(selectors):
    # The bundled gallery guards backward compatibility; tests/cases holds the
    # small single-variable figures that pin each new v0.4 feature.
    found = sorted(ROOT.glob("examples/*/*.typ")) + sorted(ROOT.glob("tests/cases/*.typ"))
    if selectors:
        found = [p for p in found if p.stem in selectors]
        missing = set(selectors) - {p.stem for p in found}
        for name in sorted(missing):
            print(f"  no such example: {name}")
    return found


def compare(src):
    """Render one example and diff it. Returns (status, detail)."""
    out = CURRENT / f"{src.stem}.png"
    proc = subprocess.run(
        ["typst", "compile", "--root", str(ROOT), "--ppi", PPI,
         "--format", "png", str(src), str(out)],
        capture_output=True, text=True,
    )
    if proc.returncode != 0:
        return "ERROR", proc.stderr.strip().splitlines()[-1] if proc.stderr else "compile failed"

    gold = GOLDEN / out.name
    if not gold.exists():
        return "NEW", "no baseline; run tests/bless.sh"

    a = Image.open(gold).convert("RGB")
    b = Image.open(out).convert("RGB")
    if a.size != b.size:
        return "CHANGED", f"size {a.size} -> {b.size}"

    bbox = ImageChops.difference(a, b).getbbox()
    if bbox is None:
        return "OK", ""

    # Report how much of the canvas moved, so trivial and sweeping changes are
    # distinguishable at a glance.
    area = (bbox[2] - bbox[0]) * (bbox[3] - bbox[1])
    pct = 100.0 * area / (a.size[0] * a.size[1])
    return "CHANGED", f"bbox {bbox} ({pct:.1f}% of canvas)"


def main():
    CURRENT.mkdir(parents=True, exist_ok=True)
    srcs = examples(set(sys.argv[1:]))
    if not srcs:
        print("no examples matched")
        return 1

    width = max(len(s.stem) for s in srcs)
    failures = 0
    for src in srcs:
        status, detail = compare(src)
        if status != "OK":
            failures += 1
        print(f"  {status:<8} {src.stem:<{width}}  {detail}".rstrip())

    print()
    print(f"{len(srcs) - failures}/{len(srcs)} match")
    if failures:
        print("Inspect tests/current/ against tests/golden/. "
              "If a change is intended, re-baseline it with tests/bless.sh <path>.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())

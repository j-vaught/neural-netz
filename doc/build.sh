#!/usr/bin/env bash
# Build the manual.
#
# Every figure is a standalone file under doc/examples/. Each is compiled to its
# own PDF in doc/build/, and the manual includes those rather than drawing
# anything inline. So an example that stops compiling stops the build here, with
# the name of the file that broke, instead of vanishing from a page.
#
#   doc/build.sh              build every example, then the manual
#   doc/build.sh basic-block  rebuild one example and the manual
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p doc/build

if [ "$#" -gt 0 ]; then
  files=()
  for name in "$@"; do files+=("doc/examples/${name%.typ}.typ"); done
else
  files=(doc/examples/*.typ)
fi

failed=()
for src in "${files[@]}"; do
  name="$(basename "${src%.typ}")"
  if typst compile --root . "$src" "doc/build/${name}.pdf" 2>doc/build/.err; then
    printf '  %-28s ok\n' "$name"
  else
    printf '  %-28s FAILED\n' "$name"
    sed 's/^/      /' doc/build/.err | head -6
    failed+=("$name")
  fi
done
rm -f doc/build/.err

if [ "${#failed[@]}" -gt 0 ]; then
  echo
  echo "${#failed[@]} example(s) failed: ${failed[*]}"
  exit 1
fi

echo
typst compile --root . doc/manual.typ doc/neural-netz-manual.pdf
echo "doc/neural-netz-manual.pdf  ($(typst --version | awk '{print $1, $2}'), ${#files[@]} figures)"

// Exposes the package's own option tables for tooling, via `typst query`.
// Used by doc/gen-llms.py so the generated reference cannot drift from the code.
#import "../src/schema.typ": layer-keys, connection-keys, group-keys
#metadata((
  layers: layer-keys,
  connection: connection-keys,
  group: group-keys,
)) <neural-netz-keys>

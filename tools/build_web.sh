#!/usr/bin/env bash
# Exports the Web build headlessly to build/web.
#   tools/build_web.sh           -> release build (small, fast)
#   MODE=debug tools/build_web.sh -> debug build (readable errors in the browser console)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tools/godot_path.sh"
GODOT_BIN="$(find_godot)"
MODE="${MODE:-release}"
OUT="$ROOT/build/web"

echo "==> Godot: $GODOT_BIN ($("$GODOT_BIN" --version))"
rm -rf "$OUT"
mkdir -p "$OUT"

echo "==> Importing assets..."
"$GODOT_BIN" --headless --path "$ROOT" --import >"$ROOT/build/import.log" 2>&1 || {
  echo "Import reported problems; last lines:"; tail -20 "$ROOT/build/import.log"; }

echo "==> Exporting Web ($MODE)..."
"$GODOT_BIN" --headless --path "$ROOT" "--export-$MODE" "Web" "$OUT/index.html" 2>&1 | tee "$ROOT/build/export.log" | grep -v -E "^\s*$" || true

if [ ! -f "$OUT/index.wasm" ] || [ ! -f "$OUT/index.pck" ]; then
  echo "ERROR: export failed (no index.wasm / index.pck). See build/export.log" >&2
  exit 1
fi
touch "$OUT/.nojekyll"   # GitHub Pages: serve files starting with _ or . as-is

echo "==> Done. Output in build/web:"
ls -la "$OUT" | awk 'NR>1 {printf "   %10s  %s\n", $5, $9}'
echo "   total: $(du -sh "$OUT" | cut -f1)"

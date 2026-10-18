#!/usr/bin/env bash
# Regenerates the placeholder sprite sheets in art/sprites/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tools/godot_path.sh"
"$(find_godot)" --headless --path "$ROOT" -s tools/gen_placeholder_sprites.gd

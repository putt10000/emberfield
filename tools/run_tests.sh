#!/usr/bin/env bash
# Runs the headless unit tests in tests/. Exit code 0 = all passed.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tools/godot_path.sh"
GODOT_BIN="$(find_godot)"
"$GODOT_BIN" --headless --path "$ROOT" -s tests/run_tests.gd

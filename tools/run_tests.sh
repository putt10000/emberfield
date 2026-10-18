#!/usr/bin/env bash
# Runs the headless tests: unit tests (tests/test_*.gd) then the scripted
# scenario (tests/sim_test.gd). Exit code 0 = all passed.
# The import step first refreshes Godot's class-name cache (new class_name
# scripts are otherwise unknown in script mode).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tools/godot_path.sh"
GODOT_BIN="$(find_godot)"
mkdir -p "$ROOT/build"
"$GODOT_BIN" --headless --path "$ROOT" --import >"$ROOT/build/import.log" 2>&1 || true
echo "== unit tests =="
"$GODOT_BIN" --headless --path "$ROOT" -s tests/run_tests.gd
echo "== scenario =="
"$GODOT_BIN" --headless --path "$ROOT" -- --sim-test

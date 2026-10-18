# Sourced by the other scripts. Finds the Godot 4 binary.
# Override with:  GODOT=/path/to/godot tools/build_web.sh
find_godot() {
  if [ -n "${GODOT:-}" ] && [ -x "$GODOT" ]; then echo "$GODOT"; return; fi
  if command -v godot >/dev/null 2>&1; then command -v godot; return; fi
  if command -v godot4 >/dev/null 2>&1; then command -v godot4; return; fi
  if [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then
    echo /Applications/Godot.app/Contents/MacOS/Godot; return
  fi
  echo "ERROR: Godot 4 not found. Install it or set GODOT=/path/to/godot" >&2
  exit 1
}

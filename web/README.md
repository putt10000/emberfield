# web/

`shell.html` is the HTML page that wraps the game in the browser. It is Godot's
default web shell (from the 4.7.2 export template) with three additions:

- `viewport-fit=cover` so the page extends under phone notches,
- CSS custom properties `--sat/--sar/--sab/--sal` carrying the safe-area insets,
  which `autoload/device_info.gd` reads through `JavaScriptBridge`,
- `touch-action: none` / no text selection, so touches reach the game.

`$GODOT_*` placeholders are filled in by the exporter. If you upgrade Godot,
re-copy `godot.html` from the new template zip and re-apply the three changes.

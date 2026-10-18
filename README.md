# Emberfield

An original 2.5D action RPG prototype in the HD-2D style, built with Godot 4.7
(GDScript, Compatibility renderer) for phone browsers first.

## Run on this Mac
1. Open Godot, click **Import**, pick this folder's `project.godot`, then press **F5**.
   Or from a terminal: `godot --path "$(pwd)"` (the `godot` alias is set in ~/.zshrc).
2. F3 toggles the FPS / draw-call overlay. Esc opens settings (from Milestone 2).

## Test on your phone (same Wi-Fi)
```bash
tools/build_web.sh && tools/serve_web.sh
```
Open the printed `http://<ip>:8060/` URL on the phone in landscape.
The server disables caching, so a rebuild shows up on reload.

## Test from anywhere
Every push to `main` builds and deploys to GitHub Pages (see Actions tab).

## Tests
```bash
tools/run_tests.sh
```

## Layout
See `CLAUDE.md` for the rules and `docs/ROADMAP.md` for milestone status.

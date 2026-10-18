# Emberfield

An original 2.5D action RPG prototype in the HD-2D style, built with Godot 4.7
(GDScript, Compatibility renderer) for phone browsers first.

## Run on this Mac
1. Open Godot, click **Import**, pick this folder's `project.godot`, then press **F5**.
   Or from a terminal: `godot --path "$(pwd)"` (the `godot` alias is set in ~/.zshrc).
2. Controls: click the ground to walk (tap-to-move) or WASD/arrows. Click an enemy to
   target it; you walk into range and auto-attack. Esc or the MENU button opens settings
   (movement mode, shadows, glow, FPS overlay). F3 toggles the overlay.
3. On a phone: tap the ground, or switch to Joystick in settings and drag in the bottom-left area.

## Regenerate placeholder sprites
```bash
tools/gen_sprites.sh
```

## Test on your phone (same Wi-Fi)
```bash
tools/build_web.sh && tools/serve_web.sh
```
Open the printed `http://<ip>:8060/` URL on the phone in landscape.
The server disables caching, so a rebuild shows up on reload.

## Test from anywhere
Live build: https://putt10000.github.io/emberfield/ (open on your phone in landscape).
Every push to `main` rebuilds and redeploys it in about 2 minutes (see the Actions tab).

## Tests
```bash
tools/run_tests.sh
```
Runs the unit tests (combat math, helpers) and then a scripted headless scenario
that plays through targeting, a fight, enemy respawn and player respawn.

## Layout
See `CLAUDE.md` for the rules and `docs/ROADMAP.md` for milestone status.

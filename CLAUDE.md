# Emberfield — project rules for every session

Original 2.5D action RPG prototype: HD-2D look (3D low-poly world, 2D pixel-art
billboard sprites), action-RPG feel. Single-player vertical slice now, but
structured so multiplayer can be added later. The developer is new to game dev:
explain how to run and test things in plain steps, and after each milestone
commit, give exact test steps, and wait for their OK before continuing.

## Hard constraints
- Godot 4.7.2 (at /Applications/Godot.app, alias `godot`). GDScript only. No C#.
- Renderer: **Compatibility** (`gl_compatibility`). Never use SDFGI, volumetric fog,
  SSAO/SSR/SSIL, VoxelGI, or anything Compatibility lacks. Use a cheap shader or skip.
- Web export is the primary target: **thread support OFF**, single-threaded.
  Keep the download small. Test on phone browser (Chrome Android / Safari iOS), landscape.
- Base resolution 1280x720, stretch `canvas_items`, aspect `expand`. All HUD and touch
  controls live inside a `SafeAreaContainer` (ui/safe_area_container.gd).
- Performance target: 60 fps on a mid-range phone browser. Few lights, few draw calls.
  The debug overlay (F3 / corner button) shows FPS and draw calls; check it.
- Original IP only. No names, text, or assets from Ragnarok Online or Octopath Traveler.

## Visual style (HD-2D)
- World from CSG/primitives; characters as `Sprite3D`, billboard **Y axis only**,
  nearest filtering, 48x48 px frames, consistent pixel size. 4 directions;
  animations idle/walk/attack/hit/death. Placeholder sheets are generated;
  real art is dropped in by replacing PNGs with the same layout (see art/sprites/README.md).
- Camera: perspective, pitch ~30°, fixed yaw, FOV ~40, smooth follow, clamped to map.
- Lighting: one DirectionalLight3D with shadows, a few warm OmniLights, WorldEnvironment
  with tonemap + glow, vignette shader, blob shadows under sprites.

## Architecture (keep multiplayer possible)
- **Logic vs presentation**: input produces *intents* (move_to, attack_target, use_skill).
  `core/` resolves them (CombatSystem, Progression, LootSystem) and emits results on
  `EventBus`. Sprites, UI and VFX only *react* to signals. Never compute damage, cooldowns,
  EXP or loot inside a sprite/animation/UI script.
- **Data-driven**: classes, skills, enemies, loot tables are Resources in `data/*.tres`
  with definitions in `core/defs/`. No hard-coded stats in scene scripts.
- Autoloads (keep few): `EventBus` (signals only), `Settings` (user:// persisted),
  `GameState` (session data), `DeviceInfo` (platform + safe area).
- Scripts small, with a `##` doc comment at the top. Tabs for indentation. Typed GDScript.
- Tests: `tests/test_*.gd` extend `tests/lib/test_case.gd` (unit), plus `tests/sim_test.gd`,
  a scripted scenario that main.gd attaches when run with `-- --sim-test`. Run both with
  `tools/run_tests.sh`. Combat math, crit, level-up and the fight loop must stay covered.
- Entities expose `stats: Stats`, `is_alive()`, `display_name`; only CombatSystem edits hp/sp.
  Enemies request attacks via `Intent.basic_attack(self)` through `GameRules.instance.submit`.

## Controls
- Two movement modes in Settings (persisted): tap-to-move (raycast + NavigationAgent3D,
  tap marker) and floating virtual joystick (bottom-left). Multitouch: joystick and
  buttons at the same time.
- Tap enemy = target (ring + HP bar), auto-attack in range. Action bar bottom-right:
  Attack (≥96 px) + 4 skills (≥64 px) with cooldown overlay and SP cost.
- Keyboard: WASD/arrows move, click move/target, Space attack, 1-4 skills, Q potion,
  Esc settings, F3 debug overlay.

## Gotchas learned
- Godot bakes the nav mesh ~2×cell_height above the floor; keep `cell_height` small (0.05)
  and bake from collision shapes only (render-mesh parsing is slow at runtime).
- Godot 4.7 ships a native `VirtualJoystick` class; ours is `TouchJoystick`.
- The desktop app's browser pane can throttle to ~3 fps after many reloads/resizes;
  close its last tab and `preview_start` again to get real 60 fps numbers.
- Tap detection must use `InputEventScreenTouch` (mouse is emulated to touch);
  UI controls consume their touches first, so world taps use `_unhandled_input`.
- Autoloads do not exist in `godot -s script.gd` mode, so anything that needs the game
  running must go through `-- --sim-test` (see tests/sim_test.gd), not `-s`.
- The browser pane throttles to ~2 fps whenever the Claude window is hidden behind
  another app; numbers are only meaningful while it is visible.

## Workflow
- `tools/build_web.sh` exports to build/web; `tools/serve_web.sh` serves it on the LAN
  and prints the phone URL; `tools/run_tests.sh` runs headless tests.
- Pushing to `main` deploys to GitHub Pages via .github/workflows/deploy-pages.yml.
- Out of scope now: multiplayer, accounts, server, cards, party, bosses, inventory UI
  beyond potions, quests, dialogue, sound (placeholder SFX hooks only), monetization.
- Docs: docs/GDD.md (design), docs/ROADMAP.md (milestones + status). Update ROADMAP
  when a milestone lands.

# Roadmap

Status key: ✅ done · 🔄 in progress · ⬜ planned

## Milestone 1 — Foundation and phone pipeline ✅
- ✅ Godot 4.7.2 project, Compatibility renderer, 1280x720 canvas_items/expand, landscape
- ✅ Autoloads: EventBus, Settings (user://), GameState, DeviceInfo (safe area)
- ✅ Debug overlay (FPS, draw calls), safe-area frame test, rotate-to-landscape prompt
- ✅ Web export preset (threads off), custom shell with viewport-fit=cover
- ✅ tools/build_web.sh, tools/serve_web.sh, tools/run_tests.sh, headless test runner
- ✅ CLAUDE.md, GDD, README
- ✅ GitHub repo (github.com/putt10000/emberfield) + Pages deploy: https://putt10000.github.io/emberfield/

## Milestone 2 — HD-2D world and movement ✅
- ✅ Ember Field map: CSG terrain, walls, safe-zone disc, path; trees/rocks as MultiMesh (2 + 1 draw calls)
- ✅ Nav mesh baked at load from collision shapes (cell_height 0.05 so the mesh hugs the floor)
- ✅ Camera rig: fixed yaw, 32° pitch, FOV 40, smooth follow, clamped to map bounds, shake hook
- ✅ Lighting: shadowed sun, 4 flickering torches, ACES + glow + light fog, vignette, blob shadows
- ✅ Player: CharacterBody3D + NavigationAgent3D + Y-billboard AnimatedSprite3D from generated sheet
- ✅ Input -> Intent -> GameRules -> Player: tap-to-move (ground raycast + ring marker), floating joystick, WASD/arrows
- ✅ Settings menu (MENU button / Esc): movement mode, shadows, glow, FPS overlay; persisted to user://
- ✅ Measured in browser: 60 fps, 20-28 draw calls, ~5 ms CPU per frame

## Milestone 3 — Combat core and enemy 1 ⬜
Resource defs + data, CombatSystem, targeting, auto-attack, Mossblob AI,
damage numbers, hit flash, death anim, combat tests.

## Milestone 4 — Skills and action bar ⬜
4 skills as data, cooldowns + SP, action bar with cooldown overlays,
multitouch, knockback, crit screen shake.

## Milestone 5 — Enemy 2, progression, loot, death ⬜
Ash Wisp + projectile, EXP/level-up, loot + pickup, potion, death/respawn, HUD.

## Milestone 6 — Performance and polish ⬜
Phone profiling, shadow/glow toggles, export size, safe-area check on notch
phones, SFX hooks, docs refresh.

## Later (not scheduled)
Native Android/iOS export, desktop browser polish, handheld PC controls,
multiplayer architecture (server-authoritative CombatSystem), more classes/maps.

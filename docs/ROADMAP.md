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

## Milestone 2 — HD-2D world and movement ⬜
Field map (CSG), nav mesh, camera rig, lighting + glow + vignette, blob shadows,
player billboard sprite with generated sheet, tap-to-move + joystick + keyboard,
settings menu with persisted movement mode.

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

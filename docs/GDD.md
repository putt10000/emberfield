# Emberfield — Game Design Document (prototype)

## Pitch
A warm, hand-crafted field at dusk, seen from a low camera. You are a wandering
swordfighter clearing the ember-lit fields of creeping blobs and spitting
ash-wisps, growing stronger with every fight. HD-2D look (pixel sprites in a
soft 3D world), snappy action-RPG combat built for thumbs.

## Scope of this phase (vertical slice)
One map, one class, two enemy types, simple combat, leveling, loot, death and
respawn. Phone browser in landscape at a smooth 60 fps. No multiplayer yet, but
logic and presentation are separated so it can be added.

## World
- **Ember Field**: one outdoor area roughly 3-4 screens wide. A stone-ringed
  **safe zone** with torches near the spawn; no enemies spawn or path inside it.
- Props: low-poly trees, rocks, fences, torches (warm point lights).
- Day state fixed at golden-hour dusk for the HD-2D mood.

## Player: Swordfighter
Stats: Level, EXP, HP, SP, ATK, DEF, attack speed, move speed, crit rate.
Auto-attacks the current target when in range.

| Skill | Type | Effect | Cooldown | SP |
|---|---|---|---|---|
| Cleave | heavy single-target | 2.2x ATK, knockback, range 1.9 m | 6 s | 12 |
| Ember Whirl | short-range AoE | 1.2x ATK to all within 2.6 m | 8 s | 18 |
| Lunge | dash | dash up to 4 m toward target/facing, 0.8x ATK to enemies within 1.4 m on landing | 5 s | 8 |
| Second Wind | self-heal | heal 30% max HP | 15 s | 20 |

SP regenerates 0.8/s out of combat and 0.3/s in combat (no damage dealt/taken for 4 s = out of combat).

(Numbers are starting points, tuned in data/skills/*.tres.)

## Enemies
- **Mossblob**: slow melee. Wanders near spawn, chases when the player is within
  ~6 m, attacks in melee, leashes back when ~14 m from spawn. Respawns after 8 s.
- **Ash Wisp**: ranged. Keeps 5-7 m distance, fires a slow projectile every 2 s,
  backs off if the player closes in. Fragile.
AI states: idle → wander → chase → attack → return-to-spawn → dead.

## Combat math (single source of truth: core/combat_system.gd)
- damage = max(1, round(ATK * skill_mult - DEF * 0.5)) with ±10% variance.
- crit: roll < crit_rate → damage × 1.5, distinct number style, small screen shake.
- Attack speed = attacks per second. SP regenerates slowly out of combat.

## Progression
- EXP to next level = 20 * level^1.6 (rounded). Level-up: +HP, +SP, +ATK, +DEF
  per class growth table; full HP/SP restore; visible burst effect.
- Loot: coins (always) + potion (chance). Auto-pickup on walk-over.
- Death: short fade, respawn at the safe zone with full HP. No penalty for now.

## Controls
Landscape, multitouch. Movement mode is a persisted setting:
tap-to-move (ground tap + marker) or floating virtual joystick (bottom-left).
Tap enemy to target. Action bar bottom-right: Attack + 4 skills + potion.
Keyboard: WASD/arrows, mouse click, Space, 1-4, Q, Esc, F3.

## HUD
HP/SP bars, level + EXP bar, coin count, potion quick-use, target HP bar,
floating damage numbers, debug overlay (FPS, draw calls).

## Out of scope (this phase)
Multiplayer, accounts, server, cards, party, bosses, inventory beyond potions,
quests, dialogue, audio (hooks only), monetization.

## GameState (autoload)
## Session-wide runtime state that must outlive scene reloads: the player's
## progression and wallet. Pure data + tiny helpers. All rules that CHANGE this
## data (EXP curve, level-up growth, loot) live in core/ and are filled in from
## Milestone 3 onward. Keeping it separate from any node makes it trivial to
## replace with server-authoritative state later.
extends Node

## Where the player appears on first spawn and after death (set by the map).
var town_spawn_position: Vector3 = Vector3.ZERO

## Progression (populated in M5).
var level: int = 1
var exp_total: int = 0
var coins: int = 0
var potions: int = 0


func reset_session() -> void:
	level = 1
	exp_total = 0
	coins = 0
	potions = 0

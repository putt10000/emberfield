## EventBus (autoload)
## Global signal hub. Game logic emits results here; presentation (sprites, UI,
## VFX) only listens. Nothing in this file holds state or does calculations.
##
## Rule: visuals never call into gameplay. They react to these signals.
## Later milestones add signals here; keep them grouped and documented.
extends Node

# --- Settings / platform -----------------------------------------------------
## A persisted setting changed (see Settings autoload). key is the setting name.
signal setting_changed(key: String, value: Variant)

# --- Player lifecycle (M2+) ---------------------------------------------------
signal player_spawned(player: Node)
signal player_died()
signal player_respawned()

# --- Combat results (M3+) -----------------------------------------------------
## Emitted by CombatSystem after damage is resolved. result is a Dictionary:
## { "source": Node, "target": Node, "amount": int, "is_crit": bool, "skill_id": String }
signal damage_dealt(result: Dictionary)
signal healed(target: Node, amount: int)
signal entity_died(entity: Node, killer: Node)
signal target_changed(new_target: Node)

# --- Skills (M4+) ---------------------------------------------------------------
signal skill_used(skill_id: String, caster: Node)
signal skill_cooldown_started(skill_id: String, duration: float)
signal skill_failed(skill_id: String, reason: String)

# --- Progression & loot (M5+) --------------------------------------------------
signal exp_gained(amount: int, total: int, to_next: int)
signal level_up(new_level: int)
signal stats_changed(stats: Dictionary)
signal loot_dropped(items: Array, position: Vector3)
signal item_picked_up(item_id: String, amount: int)

# --- Camera / feel ------------------------------------------------------------
signal screen_shake_requested(strength: float, duration: float)

## CombatSystem
## The one place where damage, crits, attack timing (and later skills, SP,
## cooldowns) are resolved. Entities never change each other's HP; they submit
## intents to GameRules, which calls into here. Results go out as EventBus
## signals that visuals react to.
##
## Combatants are Nodes with: `stats: Stats`, `is_alive() -> bool`,
## `global_position`, and a `display_name` property.
class_name CombatSystem
extends Node

const CRIT_MULTIPLIER := 1.5
const VARIANCE := 0.10
const DEF_FACTOR := 0.5
## How far beyond attack range a started attack may still land (target moved).
const HIT_GRACE := 1.3

var _rng := RandomNumberGenerator.new()
## instance id -> time (seconds) when that attacker may attack again.
var _next_attack_time: Dictionary = {}


# --- pure math (unit tested) ---------------------------------------------------

## damage = max(1, round((ATK * mult - DEF * 0.5) * variance * crit))
static func compute_damage(atk: int, def: int, mult: float, crit_rate: float, rng: RandomNumberGenerator) -> Dictionary:
	var base := float(atk) * mult - float(def) * DEF_FACTOR
	var variance := rng.randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
	var is_crit := rng.randf() < crit_rate
	var amount := base * variance * (CRIT_MULTIPLIER if is_crit else 1.0)
	return {"amount": maxi(1, int(round(amount))), "is_crit": is_crit}


static func planar_distance(a: Node3D, b: Node3D) -> float:
	return planar_distance_to(a.global_position, b.global_position)


static func planar_distance_to(pa: Vector3, pb: Vector3) -> float:
	return Vector2(pa.x, pa.z).distance_to(Vector2(pb.x, pb.z))


# --- basic attacks --------------------------------------------------------------

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func can_basic_attack(attacker: Node) -> bool:
	return _now() >= float(_next_attack_time.get(attacker.get_instance_id(), 0.0))


func in_attack_range(attacker: Node3D, target: Node3D) -> bool:
	return planar_distance(attacker, target) <= attacker.stats.attack_range


## Starts a basic attack if the attacker is alive, off cooldown and in range.
## Damage lands after the attacker's hit_delay. Returns true if the swing began.
func try_basic_attack(attacker: Node3D, target: Node3D) -> bool:
	if attacker == null or target == null or not is_instance_valid(target):
		return false
	if not attacker.is_alive() or not target.is_alive():
		return false
	if not can_basic_attack(attacker) or not in_attack_range(attacker, target):
		return false
	var s: Stats = attacker.stats
	_next_attack_time[attacker.get_instance_id()] = _now() + 1.0 / maxf(s.attack_speed, 0.05)
	EventBus.attack_started.emit(attacker, target)
	if s.hit_delay <= 0.0:
		_land_basic_hit(attacker, target)
	else:
		get_tree().create_timer(s.hit_delay).timeout.connect(_land_basic_hit.bind(attacker, target))
	return true


func _land_basic_hit(attacker: Node3D, target: Node3D) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	if not attacker.is_alive() or not target.is_alive():
		return
	if planar_distance(attacker, target) > attacker.stats.attack_range * HIT_GRACE:
		return
	apply_damage(attacker, target, 1.0, &"")


## Applies damage from source to target and broadcasts the result.
func apply_damage(source: Node, target: Node, mult: float, skill_id: StringName) -> Dictionary:
	var ts: Stats = target.stats
	var ss: Stats = source.stats
	var roll := compute_damage(ss.atk, ts.def, mult, ss.crit_rate, _rng)
	ts.hp = maxi(0, ts.hp - roll.amount)
	var result := {
		"source": source, "target": target, "amount": roll.amount,
		"is_crit": roll.is_crit, "skill_id": skill_id,
	}
	EventBus.damage_dealt.emit(result)
	if ts.hp <= 0:
		EventBus.entity_died.emit(target, source)
	return result


func heal(target: Node, amount: int) -> void:
	var ts: Stats = target.stats
	var before := ts.hp
	ts.hp = mini(ts.max_hp, ts.hp + amount)
	if ts.hp != before:
		EventBus.healed.emit(target, ts.hp - before)


## Clears cooldown bookkeeping for an entity that respawned.
func reset_attacker(attacker: Node) -> void:
	_next_attack_time.erase(attacker.get_instance_id())

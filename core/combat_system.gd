## CombatSystem
## The one place where damage, crits, attack timing, skills, SP and cooldowns
## are resolved. Entities never change each other's HP/SP; they submit intents
## to GameRules, which calls into here. Results go out as EventBus signals that
## visuals react to.
##
## Combatants are Nodes with: `stats: Stats`, `is_alive() -> bool`,
## `global_position`, `display_name`. Optional: `apply_knockback(impulse)`,
## `start_dash(direction, distance)`, `get_skills() -> Array[SkillDef]`,
## `class_def` (for SP regen rates).
class_name CombatSystem
extends Node

const CRIT_MULTIPLIER := 1.5
const VARIANCE := 0.10
const DEF_FACTOR := 0.5
## How far beyond attack range a started attack may still land (target moved).
const HIT_GRACE := 1.3
## Seconds after dealing/taking damage during which SP regenerates slowly.
const IN_COMBAT_SECONDS := 4.0
const DASH_SECONDS := 0.22

var _rng := RandomNumberGenerator.new()
## instance id -> time (seconds) when that attacker may attack again.
var _next_attack_time: Dictionary = {}
## instance id -> { skill_id: ready_time }
var _skill_ready: Dictionary = {}
## instance id -> time of last damage dealt or taken
var _last_combat_time: Dictionary = {}
## Entities whose SP regenerates (the player). instance id -> Node
var _regen_entities: Dictionary = {}
var _sp_accum: Dictionary = {}


# --- pure math (unit tested) ---------------------------------------------------

## damage = max(1, round((ATK * mult - DEF * 0.5) * variance * crit))
static func compute_damage(atk: int, def: int, mult: float, crit_rate: float, rng: RandomNumberGenerator) -> Dictionary:
	var base := float(atk) * mult - float(def) * DEF_FACTOR
	var variance := rng.randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
	var is_crit := rng.randf() < crit_rate
	var amount := base * variance * (CRIT_MULTIPLIER if is_crit else 1.0)
	return {"amount": maxi(1, int(round(amount))), "is_crit": is_crit}


## Why a skill cannot be used right now, or &"" if it can.
## dist is the planar distance to the target (INF when there is none).
static func skill_blocker(stats: Stats, skill: SkillDef, ready_time: float, now: float, has_target: bool, dist: float) -> StringName:
	if now < ready_time:
		return &"cooldown"
	if stats.sp < skill.sp_cost:
		return &"no_sp"
	if skill.kind == SkillDef.Kind.STRIKE:
		if not has_target:
			return &"no_target"
		if dist > skill.range:
			return &"out_of_range"
	return &""


static func planar_distance(a: Node3D, b: Node3D) -> float:
	return planar_distance_to(a.global_position, b.global_position)


static func planar_distance_to(pa: Vector3, pb: Vector3) -> float:
	return Vector2(pa.x, pa.z).distance_to(Vector2(pb.x, pb.z))


# --- time + bookkeeping ---------------------------------------------------------

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _mark_combat(entity: Node) -> void:
	_last_combat_time[entity.get_instance_id()] = _now()


func is_in_combat(entity: Node) -> bool:
	return _now() - float(_last_combat_time.get(entity.get_instance_id(), -INF)) < IN_COMBAT_SECONDS


## Clears cooldown bookkeeping for an entity that respawned.
func reset_attacker(attacker: Node) -> void:
	var id := attacker.get_instance_id()
	_next_attack_time.erase(id)
	_skill_ready.erase(id)
	_last_combat_time.erase(id)
	_sp_accum.erase(id)


## Entities registered here regenerate SP every frame (see _process).
func register_sp_regen(entity: Node) -> void:
	_regen_entities[entity.get_instance_id()] = entity


func _process(delta: float) -> void:
	for id in _regen_entities.keys():
		var e: Node = _regen_entities[id]
		if not is_instance_valid(e) or not e.is_alive():
			continue
		var s: Stats = e.stats
		if s.sp >= s.max_sp:
			_sp_accum[id] = 0.0
			continue
		var cd: ClassDef = e.get("class_def")
		var rate := 0.5
		if cd:
			rate = cd.sp_regen_in_combat if is_in_combat(e) else cd.sp_regen_out_of_combat
		var acc: float = float(_sp_accum.get(id, 0.0)) + rate * delta
		if acc >= 1.0:
			var whole := int(acc)
			s.sp = mini(s.max_sp, s.sp + whole)
			acc -= whole
		_sp_accum[id] = acc


# --- basic attacks --------------------------------------------------------------

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
	_mark_combat(source)
	_mark_combat(target)
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


# --- skills ----------------------------------------------------------------------

func get_cooldown_remaining(caster: Node, skill_id: StringName) -> float:
	var table: Dictionary = _skill_ready.get(caster.get_instance_id(), {})
	return maxf(0.0, float(table.get(skill_id, 0.0)) - _now())


## Resolves a skill use. Returns &"" on success or the blocker reason.
func use_skill(caster: Node3D, skill: SkillDef, target: Node3D) -> StringName:
	if caster == null or skill == null or not caster.is_alive():
		return &"invalid"
	if target != null and (not is_instance_valid(target) or not target.is_alive()):
		target = null
	var dist := planar_distance(caster, target) if target else INF
	var table: Dictionary = _skill_ready.get(caster.get_instance_id(), {})
	var reason := skill_blocker(caster.stats, skill, float(table.get(skill.id, 0.0)), _now(), target != null, dist)
	if reason != &"":
		EventBus.skill_failed.emit(skill.id, reason)
		return reason
	# Pay and start the cooldown first; effects follow.
	caster.stats.sp -= skill.sp_cost
	table[skill.id] = _now() + skill.cooldown
	_skill_ready[caster.get_instance_id()] = table
	EventBus.skill_used.emit(skill.id, caster)
	EventBus.skill_cooldown_started.emit(skill.id, skill.cooldown)
	match skill.kind:
		SkillDef.Kind.STRIKE:
			apply_damage(caster, target, skill.power, skill.id)
			if skill.knockback > 0.0 and target.has_method("apply_knockback"):
				var away := target.global_position - caster.global_position
				away.y = 0.0
				target.apply_knockback(away.normalized() * skill.knockback)
		SkillDef.Kind.AOE:
			for e in _enemies_within(caster, caster.global_position, skill.radius):
				apply_damage(caster, e, skill.power, skill.id)
		SkillDef.Kind.DASH:
			var dir := Vector3.ZERO
			if target:
				dir = target.global_position - caster.global_position
			elif caster.get("facing") != null:
				var f2: Vector2 = Facing.to_vector(int(caster.get("facing")))
				dir = Vector3(f2.x, 0.0, f2.y)
			dir.y = 0.0
			if dir.length() < 0.01:
				dir = Vector3(0, 0, 1)
			var distance: float = skill.radius
			if target:
				distance = minf(distance, maxf(0.0, dir.length() - 0.9))
			if caster.has_method("start_dash"):
				caster.start_dash(dir.normalized(), distance, DASH_SECONDS)
			get_tree().create_timer(DASH_SECONDS).timeout.connect(_land_dash.bind(caster, skill))
		SkillDef.Kind.HEAL:
			heal(caster, int(round(caster.stats.max_hp * skill.power)))
	return &""


func _land_dash(caster: Node3D, skill: SkillDef) -> void:
	if not is_instance_valid(caster) or not caster.is_alive():
		return
	for e in _enemies_within(caster, caster.global_position, skill.knockback):
		apply_damage(caster, e, skill.power, skill.id)


func _enemies_within(caster: Node, center: Vector3, radius: float) -> Array[Node]:
	var out: Array[Node] = []
	for e in get_tree().get_nodes_in_group("enemy"):
		if e == caster or not e.is_alive():
			continue
		if planar_distance_to(e.global_position, center) <= radius:
			out.append(e)
	return out

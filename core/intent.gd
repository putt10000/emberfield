## Intent
## A request for something to happen, produced by input (and later by the
## network). Input code only builds intents; GameRules decides what they do;
## visuals never see them. Keeping this boundary is what makes multiplayer
## possible later: a client sends intents, a server resolves them.
class_name Intent
extends RefCounted

enum Type { MOVE_TO, MOVE_DIR, STOP, ATTACK_TARGET, BASIC_ATTACK, USE_SKILL, USE_POTION }

var type: Type
## Who issued it (an enemy AI, or null for the local player).
var source: Node = null
## MOVE_TO: world position to walk to.
var position: Vector3 = Vector3.ZERO
## MOVE_DIR: x = world X (screen right), y = world Z (screen down). Length 0..1.
var direction: Vector2 = Vector2.ZERO
## ATTACK_TARGET: select this enemy as the player's target.
var target: Node = null
## USE_SKILL: id from data/skills.
var skill_id: StringName = &""


static func move_to(p: Vector3) -> Intent:
	var i := Intent.new()
	i.type = Type.MOVE_TO
	i.position = p
	return i


static func move_dir(d: Vector2) -> Intent:
	var i := Intent.new()
	i.type = Type.MOVE_DIR
	i.direction = d.limit_length(1.0)
	return i


static func stop() -> Intent:
	var i := Intent.new()
	i.type = Type.STOP
	return i


static func attack_target(t: Node) -> Intent:
	var i := Intent.new()
	i.type = Type.ATTACK_TARGET
	i.target = t
	return i


## BASIC_ATTACK: source swings at its current target (CombatSystem checks range/cooldown).
static func basic_attack(src: Node) -> Intent:
	var i := Intent.new()
	i.type = Type.BASIC_ATTACK
	i.source = src
	return i


static func use_skill(id: StringName, src: Node = null) -> Intent:
	var i := Intent.new()
	i.type = Type.USE_SKILL
	i.skill_id = id
	i.source = src
	return i

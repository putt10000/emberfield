## GameRules
## The single entry point for intents. Movement intents go to the player body,
## targeting sets the player's target, attacks and skills go to CombatSystem.
## Everything that changes game state passes through here, so a future server
## can own this node and clients only submit intents.
class_name GameRules
extends Node

## Attack button with no target: pick the nearest enemy within this range.
const AUTO_TARGET_RANGE := 8.0

static var instance: GameRules

var player: Node = null:
	set(value):
		player = value
		if player:
			combat.register_sp_regen(player)
var combat: CombatSystem


func _ready() -> void:
	instance = self
	combat = CombatSystem.new()
	combat.name = "CombatSystem"
	add_child(combat)


func submit(intent: Intent) -> void:
	match intent.type:
		Intent.Type.MOVE_TO, Intent.Type.MOVE_DIR, Intent.Type.STOP:
			if player:
				player.apply_move_intent(intent)
		Intent.Type.ATTACK_TARGET:
			if player:
				player.set_target(intent.target)
		Intent.Type.BASIC_ATTACK:
			var source: Node = intent.source if intent.source else player
			if source == null or not source.has_method("get_target"):
				return
			if source == player and player.get_target() == null:
				player.set_target(nearest_enemy_to(player, AUTO_TARGET_RANGE))
			combat.try_basic_attack(source, source.get_target())
		Intent.Type.USE_SKILL:
			var caster: Node = intent.source if intent.source else player
			if caster == null:
				return
			var skill := find_skill(caster, intent.skill_id)
			if skill == null:
				return
			var target: Node = caster.get_target() if caster.has_method("get_target") else null
			if caster == player and target == null and skill.kind == SkillDef.Kind.STRIKE:
				player.set_target(nearest_enemy_to(player, skill.range + 0.5))
				target = player.get_target()
			combat.use_skill(caster, skill, target)
		_:
			pass  # Milestone 5: potion.


func find_skill(caster: Node, id: StringName) -> SkillDef:
	if not caster.has_method("get_skills"):
		return null
	for s in caster.get_skills():
		if s and s.id == id:
			return s
	return null


func nearest_enemy_to(node: Node3D, max_range: float) -> Node:
	var best: Node = null
	var best_d := max_range
	for e in get_tree().get_nodes_in_group("enemy"):
		if not e.is_alive() or not e.visible:
			continue
		var d := CombatSystem.planar_distance(node, e)
		if d < best_d:
			best_d = d
			best = e
	return best


## Milestone 3 placeholder: instant respawn at town. Milestone 5 adds the fade.
func respawn_player() -> void:
	if player:
		player.respawn(GameState.town_spawn_position)

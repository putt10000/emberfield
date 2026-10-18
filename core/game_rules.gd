## GameRules
## The single entry point for intents. Movement intents go to the player body,
## targeting sets the player's target, and attack intents go to CombatSystem.
## Everything that changes game state passes through here, so a future server
## can own this node and clients only submit intents.
class_name GameRules
extends Node

static var instance: GameRules

var player: Node = null
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
			if source and source.has_method("get_target"):
				combat.try_basic_attack(source, source.get_target())
		_:
			pass  # Milestone 4+: skills / potion.


## Milestone 3 placeholder: instant respawn at town. Milestone 5 adds the fade.
func respawn_player() -> void:
	if player:
		player.respawn(GameState.town_spawn_position)

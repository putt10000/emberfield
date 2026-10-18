## GameRules
## The single entry point for intents. Movement intents go to the player body;
## combat intents (from Milestone 3) go to CombatSystem. Everything that changes
## game state passes through here, so a future server can own this node and
## clients only submit intents.
class_name GameRules
extends Node

var player: Node = null


func submit(intent: Intent) -> void:
	if player == null:
		return
	match intent.type:
		Intent.Type.MOVE_TO, Intent.Type.MOVE_DIR, Intent.Type.STOP:
			player.apply_move_intent(intent)
		_:
			pass  # Milestone 3+: attack / skills / potion.

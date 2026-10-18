## Main
## Root scene: hosts the world (field + camera + tap marker), spawns the player,
## and wires input -> GameRules -> player. UI layers live here too.
extends Node

const PLAYER_SCENE := preload("res://entities/player/player.tscn")

@onready var world: Node3D = $World
@onready var camera_rig: CameraRig = $World/CameraRig
@onready var tap_marker: Node3D = $World/TapMarker
@onready var rules: GameRules = $GameRules
@onready var input_controller: InputController = $InputController
@onready var hud: CanvasLayer = $HUD
@onready var settings_menu: CanvasLayer = $SettingsMenu

var player: Player


func _ready() -> void:
	print("Emberfield %s | Godot %s | %s" % [
		ProjectSettings.get_setting("application/config/version"),
		Engine.get_version_info().string,
		RenderingServer.get_current_rendering_method()])
	_spawn_player()
	input_controller.camera = camera_rig.camera
	input_controller.tap_marker = tap_marker
	input_controller.joystick = hud.joystick
	input_controller.intent_issued.connect(rules.submit)
	hud.menu_requested.connect(settings_menu.toggle)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	world.add_child(player)
	player.global_position = GameState.town_spawn_position
	camera_rig.target = player
	camera_rig.snap_to_target()
	rules.player = player
	EventBus.player_spawned.emit(player)

## Main
## Root scene. In Milestone 1 it only hosts a tiny 3D test world plus the
## overlays, proving the Compatibility renderer, stretch settings, safe area
## and debug readout all work on the phone. Milestone 2 replaces the test
## world with world/field.tscn and the player.
extends Node

@onready var _sun: DirectionalLight3D = $World/Sun
@onready var _spinner: MeshInstance3D = $World/Spinner


func _ready() -> void:
	_sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	print("Emberfield %s | Godot %s | %s" % [
		ProjectSettings.get_setting("application/config/version"),
		Engine.get_version_info().string,
		RenderingServer.get_current_rendering_method()])


func _process(delta: float) -> void:
	# A moving object makes dropped frames visible to the eye during the test.
	_spinner.rotate_y(delta * 1.2)

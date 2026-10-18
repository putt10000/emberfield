## CameraRig
## HD-2D camera: perspective, fixed yaw (never rotates), low pitch, narrow FOV.
## Follows a target smoothly and is clamped to the map bounds. Listens for
## screen-shake requests from EventBus (visual only; nothing reads back from it).
class_name CameraRig
extends Node3D

@export var target: Node3D
@export var pitch_degrees: float = 32.0
@export var distance: float = 14.0
@export var fov: float = 40.0
@export var follow_speed: float = 7.0
## Height of the focus point above the target's feet.
@export var focus_height: float = 0.8
## Allowed XZ range for the focus point (x, z, width, depth).
@export var bounds: Rect2 = Rect2(-15, -9, 30, 19)

@onready var camera: Camera3D = $Camera3D

var _shake_time := 0.0
var _shake_duration := 0.0
var _shake_strength := 0.0


func _ready() -> void:
	apply_geometry()
	EventBus.screen_shake_requested.connect(_on_shake)
	if target:
		snap_to_target()


func apply_geometry() -> void:
	var p := deg_to_rad(pitch_degrees)
	camera.position = Vector3(0.0, sin(p) * distance, cos(p) * distance)
	camera.rotation = Vector3(-p, 0.0, 0.0)
	camera.fov = fov


func snap_to_target() -> void:
	if target:
		global_position = _goal()


func _goal() -> Vector3:
	var t := target.global_position
	var x := clampf(t.x, bounds.position.x, bounds.end.x)
	var z := clampf(t.z, bounds.position.y, bounds.end.y)
	return Vector3(x, focus_height, z)


func _physics_process(delta: float) -> void:
	if target:
		global_position = global_position.lerp(_goal(), 1.0 - exp(-follow_speed * delta))
	if _shake_time > 0.0:
		_shake_time -= delta
		var k := _shake_strength * (_shake_time / _shake_duration)
		camera.h_offset = randf_range(-k, k)
		camera.v_offset = randf_range(-k, k)
	elif camera.h_offset != 0.0 or camera.v_offset != 0.0:
		camera.h_offset = 0.0
		camera.v_offset = 0.0


func _on_shake(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_duration = maxf(duration, 0.01)
	_shake_time = duration

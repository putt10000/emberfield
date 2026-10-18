## InputController
## Turns raw input into Intents and emits them. Nothing moves here.
##  - Tap on the ground (tap-to-move mode): raycast to the ground -> MOVE_TO.
##  - Virtual joystick / keyboard (WASD, arrows): MOVE_DIR each time it changes.
## UI controls consume their own touches first, so only taps that reach
## _unhandled_input count as world taps.
class_name InputController
extends Node

signal intent_issued(intent: Intent)

@export var camera: Camera3D
@export var tap_marker: Node3D
@export var joystick: TouchJoystick:
	set(value):
		joystick = value
		if joystick:
			joystick.direction_changed.connect(func(d: Vector2) -> void: _joy_dir = d)

const GROUND_MASK := 1
const TAP_MAX_DRIFT := 24.0
const TAP_MAX_SECONDS := 0.4

var _press_index := -1
var _press_pos := Vector2.ZERO
var _press_time := 0.0
var _pending_tap := Vector2.INF
var _joy_dir := Vector2.ZERO
var _last_dir := Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if _press_index == -1:
				_press_index = t.index
				_press_pos = t.position
				_press_time = Time.get_ticks_msec() / 1000.0
		elif t.index == _press_index:
			_press_index = -1
			var held := Time.get_ticks_msec() / 1000.0 - _press_time
			if t.position.distance_to(_press_pos) <= TAP_MAX_DRIFT and held <= TAP_MAX_SECONDS:
				_pending_tap = t.position


func _process(_delta: float) -> void:
	var kb := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := kb if kb != Vector2.ZERO else _joy_dir
	if dir != _last_dir:
		_last_dir = dir
		intent_issued.emit(Intent.move_dir(dir))


func _physics_process(_delta: float) -> void:
	if _pending_tap == Vector2.INF:
		return
	var screen_pos := _pending_tap
	_pending_tap = Vector2.INF
	if int(Settings.get_value("movement_mode")) != Settings.MovementMode.TAP_TO_MOVE:
		return  # Milestone 3: taps still select enemies in joystick mode.
	var hit := _raycast_ground(screen_pos)
	if hit == Vector3.INF:
		return
	if tap_marker:
		tap_marker.show_at(hit)
	intent_issued.emit(Intent.move_to(hit))


func _raycast_ground(screen_pos: Vector2) -> Vector3:
	if camera == null:
		return Vector3.INF
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 200.0
	var query := PhysicsRayQueryParameters3D.create(from, to, GROUND_MASK)
	var result := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return Vector3.INF
	return result["position"]

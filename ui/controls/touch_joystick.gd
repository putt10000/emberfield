## TouchJoystick
## Floating joystick: appears where the thumb lands inside this control's area,
## follows the drag, disappears on release. Tracks one touch index so other
## fingers can press buttons at the same time. Emits a direction in
## screen space (x right, y down), length 0..1.
class_name TouchJoystick
extends Control

signal direction_changed(dir: Vector2)

@export var radius: float = 70.0
@export var knob_radius: float = 30.0
@export var deadzone: float = 0.12

var _touch_index := -1
var _center := Vector2.ZERO
var _knob := Vector2.ZERO
var _dir := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_mode(int(Settings.get_value("movement_mode")))
	EventBus.setting_changed.connect(_on_setting_changed)


func _on_setting_changed(key: String, value: Variant) -> void:
	if key == "movement_mode":
		_apply_mode(int(value))


func _apply_mode(mode: int) -> void:
	visible = mode == Settings.MovementMode.JOYSTICK
	if not visible:
		_release()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _touch_index == -1:
			_touch_index = t.index
			_center = t.position
			_knob = t.position
			_emit(Vector2.ZERO)
			queue_redraw()
			accept_event()
		elif not t.pressed and t.index == _touch_index:
			_release()
			accept_event()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch_index:
			var offset := d.position - _center
			if offset.length() > radius:
				# Floating: drag the base along when the thumb goes past the rim.
				_center = d.position - offset.normalized() * radius
				offset = d.position - _center
			_knob = d.position
			var v := offset / radius
			_emit(Vector2.ZERO if v.length() < deadzone else v)
			queue_redraw()
			accept_event()


func _release() -> void:
	_touch_index = -1
	_emit(Vector2.ZERO)
	queue_redraw()


func _emit(v: Vector2) -> void:
	if v != _dir:
		_dir = v
		direction_changed.emit(v)


func _draw() -> void:
	if _touch_index == -1:
		return
	draw_circle(_center, radius, Color(1, 1, 1, 0.12))
	draw_arc(_center, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.45), 2.0, true)
	draw_circle(_knob, knob_radius, Color(1, 0.9, 0.7, 0.55))

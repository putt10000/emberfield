## WorldBars
## Draws small HP bars above enemies that are hurt or targeted, by projecting
## their world position to the screen. One Control, one _draw, no per-enemy nodes.
extends Control

const BAR_W := 46.0
const BAR_H := 6.0
const HEAD_OFFSET := Vector3(0.0, 1.75, 0.0)

var _target: Node = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.target_changed.connect(func(t: Node) -> void: _target = t)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	for e in get_tree().get_nodes_in_group("enemy"):
		if not e.visible or not e.is_alive():
			continue
		var hurt: bool = e.stats.hp < e.stats.max_hp
		if not hurt and e != _target:
			continue
		var p: Vector3 = e.global_position + HEAD_OFFSET
		if cam.is_position_behind(p):
			continue
		var s := cam.unproject_position(p) - global_position
		var top_left := Vector2(s.x - BAR_W * 0.5, s.y - BAR_H)
		draw_rect(Rect2(top_left - Vector2(1, 1), Vector2(BAR_W + 2, BAR_H + 2)), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(top_left, Vector2(BAR_W * e.stats.hp_ratio(), BAR_H)), Color(0.9, 0.25, 0.2, 1.0))

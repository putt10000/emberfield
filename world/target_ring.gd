## TargetRing — red ring under the player's current target. Visual only.
extends MeshInstance3D

var _target: Node3D = null
var _t := 0.0


func _ready() -> void:
	visible = false
	EventBus.target_changed.connect(_on_target_changed)
	EventBus.entity_died.connect(func(e: Node, _k: Node) -> void:
		if e == _target:
			_on_target_changed(null))


func _on_target_changed(t: Node) -> void:
	_target = t as Node3D
	visible = _target != null


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		visible = false
		return
	_t += delta
	global_position = _target.global_position + Vector3(0.0, 0.03, 0.0)
	var s := 1.0 + 0.06 * sin(_t * 6.0)
	scale = Vector3(s, 1.0, s)

## DamageNumbers
## Spawns floating numbers for damage (and heals). Pure presentation: listens
## to EventBus and never touches stats. Crits are bigger and orange.
extends Node3D

const RISE := 1.1
const LIFETIME := 0.85


func _ready() -> void:
	EventBus.damage_dealt.connect(_on_damage)
	EventBus.healed.connect(_on_heal)


func _on_damage(result: Dictionary) -> void:
	var target: Node3D = result.target as Node3D
	if target == null or not is_instance_valid(target):
		return
	var crit: bool = result.is_crit
	_spawn(target.global_position, str(result.amount) + ("!" if crit else ""),
		Color(1.0, 0.8, 0.25) if crit else Color(1, 1, 1), 60 if crit else 42)


func _on_heal(target: Node, amount: int) -> void:
	var t := target as Node3D
	if t and is_instance_valid(t):
		_spawn(t.global_position, "+" + str(amount), Color(0.45, 1.0, 0.5), 42)


func _spawn(at: Vector3, text: String, color: Color, size: int) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.outline_size = 12
	label.pixel_size = 0.012
	label.modulate = color
	label.outline_modulate = Color(0.08, 0.05, 0.1, 1.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 10
	label.position = at + Vector3(randf_range(-0.25, 0.25), 1.7, 0.0)
	add_child(label)
	var start_scale := Vector3(1.3, 1.3, 1.3) if size > 50 else Vector3(1, 1, 1)
	label.scale = start_scale
	var tw := create_tween().set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y + RISE, LIFETIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(label, "scale", Vector3.ONE, 0.18)
	tw.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(LIFETIME - 0.3)
	tw.tween_property(label, "outline_modulate:a", 0.0, 0.3).set_delay(LIFETIME - 0.3)
	tw.chain().tween_callback(label.queue_free)

## SkillVfx
## Cheap visual effects for skills (presentation only, listens to EventBus):
## an expanding ember ring for Ember Whirl, a short ground flash for Cleave.
extends Node3D

const RING_SHADER := preload("res://shaders/ring.gdshader")

var _quad: PlaneMesh


func _ready() -> void:
	_quad = PlaneMesh.new()
	_quad.size = Vector2(1, 1)
	EventBus.skill_used.connect(_on_skill_used)


func _on_skill_used(skill_id: StringName, caster: Node) -> void:
	var c := caster as Node3D
	if c == null:
		return
	match skill_id:
		&"ember_whirl":
			_ring(c.global_position, Color(1.0, 0.55, 0.2, 1.0), 0.6, 5.2, 0.35)
		&"cleave":
			_ring(c.global_position, Color(1.0, 0.9, 0.6, 1.0), 1.2, 2.2, 0.2)
		&"lunge":
			_ring(c.global_position, Color(0.7, 0.85, 1.0, 1.0), 1.0, 2.0, 0.25)
		&"second_wind":
			_ring(c.global_position, Color(0.5, 1.0, 0.6, 1.0), 2.4, 0.6, 0.45)


func _ring(at: Vector3, color: Color, from_scale: float, to_scale: float, seconds: float) -> void:
	var m := MeshInstance3D.new()
	m.mesh = _quad
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = RING_SHADER
	mat.set_shader_parameter("color", color)
	mat.set_shader_parameter("radius", 0.42)
	mat.set_shader_parameter("thickness", 0.08)
	mat.set_shader_parameter("alpha", 1.0)
	m.material_override = mat
	m.position = at + Vector3(0, 0.04, 0)
	m.scale = Vector3(from_scale, 1, from_scale)
	add_child(m)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3(to_scale, 1, to_scale), seconds).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "shader_parameter/alpha", 0.0, seconds)
	tw.chain().tween_callback(m.queue_free)

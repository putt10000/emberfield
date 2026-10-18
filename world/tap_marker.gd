## TapMarker
## Small ring that appears where the player tapped the ground, then shrinks away.
extends MeshInstance3D

var _mat: ShaderMaterial
var _tween: Tween


func _ready() -> void:
	_mat = get_surface_override_material(0).duplicate()
	set_surface_override_material(0, _mat)
	visible = false


func show_at(world_pos: Vector3) -> void:
	global_position = Vector3(world_pos.x, 0.03, world_pos.z)
	visible = true
	scale = Vector3(1.4, 1.0, 1.4)
	_mat.set_shader_parameter("alpha", 1.0)
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector3(0.5, 1.0, 0.5), 0.45).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_mat, "shader_parameter/alpha", 0.0, 0.45)
	_tween.chain().tween_callback(func(): visible = false)

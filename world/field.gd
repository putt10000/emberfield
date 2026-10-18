## Field — the one map ("Ember Field").
## The root is a NavigationRegion3D so the nav mesh is baked from everything
## below it when the scene loads (small map, synchronous bake, no threads on
## web). The bake reads collision shapes only (TerrainBody + prop colliders),
## never render meshes, which keeps it fast. Note: Godot bakes the mesh about
## two cell_heights above the floor, so cell_height stays small (0.05). Trees and rocks are placed from the lists below into MultiMeshes, so
## all trees cost two draw calls and all rocks one. Replace the primitive
## meshes with real models later without touching the layout.
extends NavigationRegion3D

const TORCH := preload("res://world/props/torch.tscn")

## (x, z) of tree trunks. Map spans x -20..20, z -14..14; walls at the edges.
const TREES: Array[Vector2] = [
	Vector2(-17, -12), Vector2(-12.5, -12.3), Vector2(-8, -11.8), Vector2(-3.5, -12.2),
	Vector2(1, -11.9), Vector2(5.5, -12.3), Vector2(10, -11.8), Vector2(14.5, -12.2), Vector2(18, -11.5),
	Vector2(-17.5, 12), Vector2(-13, 12.3), Vector2(-8.5, 11.8), Vector2(-4, 12.2),
	Vector2(0.5, 11.9), Vector2(5, 12.3), Vector2(9.5, 11.8), Vector2(14, 12.2), Vector2(18, 11.6),
	Vector2(18.2, -7), Vector2(18.4, -2), Vector2(18.1, 3), Vector2(18.3, 7.5),
	Vector2(-18.3, -8), Vector2(-18.1, 7.5),
	Vector2(2.5, -5.5), Vector2(4, -7), Vector2(9.5, 4.5), Vector2(-3, 7), Vector2(12.5, -3.5),
]
## (x, z, scale) of rocks.
const ROCKS: Array[Vector3] = [
	Vector3(-6, -3, 1.0), Vector3(-5.2, -3.8, 0.6), Vector3(1, 5, 1.3), Vector3(7, -1, 0.8),
	Vector3(13, 6, 1.1), Vector3(15, -8, 0.9), Vector3(-2, -8.5, 0.7), Vector3(6, 8.5, 1.2),
	Vector3(-10, 6.5, 0.8), Vector3(16.5, 1.5, 0.7),
]
## (x, z) of torches: three around the safe zone, one along the path.
const TORCHES: Array[Vector2] = [
	Vector2(-14, -4.6), Vector2(-10.2, 2.6), Vector2(-17.8, 2.6), Vector2(-1, 1.6),
]

@onready var sun: DirectionalLight3D = $Sun
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var props: Node3D = $Props
@onready var colliders: Node3D = $Colliders

var nav_ready := false


func _ready() -> void:
	GameState.town_spawn_position = spawn_point.global_position
	sun.rotation_degrees = Vector3(-52.0, 35.0, 0.0)
	_place_trees()
	_place_rocks()
	_place_torches()
	_apply_settings()
	EventBus.setting_changed.connect(func(_k: String, _v: Variant) -> void: _apply_settings())
	# CSG meshes are generated during the first frames; bake once they exist.
	await get_tree().process_frame
	await get_tree().process_frame
	bake_navigation_mesh(false)
	nav_ready = true
	print("Field: nav mesh baked, %d polygons" % navigation_mesh.get_polygon_count())


func _apply_settings() -> void:
	sun.shadow_enabled = bool(Settings.get_value("shadows"))
	world_env.environment.glow_enabled = bool(Settings.get_value("glow"))


# --- props ---------------------------------------------------------------------

func _place_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.18
	trunk.bottom_radius = 0.26
	trunk.height = 1.4
	trunk.radial_segments = 7
	trunk.rings = 1
	trunk.material = _flat(Color(0.36, 0.24, 0.15))
	var canopy := CylinderMesh.new()
	canopy.top_radius = 0.0
	canopy.bottom_radius = 1.4
	canopy.height = 2.8
	canopy.radial_segments = 7
	canopy.rings = 1
	canopy.material = _flat(Color(0.2, 0.42, 0.22))
	var trunk_xf: Array[Transform3D] = []
	var canopy_xf: Array[Transform3D] = []
	var shape := CylinderShape3D.new()
	shape.radius = 0.42
	shape.height = 1.6
	for p in TREES:
		var s := rng.randf_range(0.85, 1.25)
		var basis := Basis.from_scale(Vector3(s, s, s)).rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		trunk_xf.append(Transform3D(basis, Vector3(p.x, 0.7 * s, p.y)))
		canopy_xf.append(Transform3D(basis, Vector3(p.x, 2.6 * s, p.y)))
		_add_collider(shape, Transform3D(Basis(), Vector3(p.x, 0.8, p.y)))
	_add_multimesh(trunk, trunk_xf, true)
	_add_multimesh(canopy, canopy_xf, true)


func _place_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var mesh := SphereMesh.new()
	mesh.radius = 0.6
	mesh.height = 0.8
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.material = _flat(Color(0.5, 0.48, 0.52))
	var xfs: Array[Transform3D] = []
	for r in ROCKS:
		var s := r.z
		var basis := Basis.from_scale(Vector3(s, s * 0.75, s)).rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		xfs.append(Transform3D(basis, Vector3(r.x, 0.2 * s, r.y)))
		var shape := SphereShape3D.new()
		shape.radius = 0.5 * s
		_add_collider(shape, Transform3D(Basis(), Vector3(r.x, 0.2 * s, r.y)))
	_add_multimesh(mesh, xfs, false)


func _place_torches() -> void:
	for p in TORCHES:
		var t := TORCH.instantiate()
		props.add_child(t)
		t.position = Vector3(p.x, 0.0, p.y)


func _add_multimesh(mesh: Mesh, xfs: Array[Transform3D], shadows: bool) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	props.add_child(mmi)


func _add_collider(shape: Shape3D, xf: Transform3D) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	colliders.add_child(body)
	body.transform = xf


func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	return m

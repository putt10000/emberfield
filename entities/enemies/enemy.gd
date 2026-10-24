## Enemy
## Body + stats for one enemy, configured entirely by an EnemyDef. Movement is
## requested by its AI child (EnemyAI); attacks go through GameRules as intents;
## HP is only changed by CombatSystem. Visual reactions (hit flash, death
## animation) listen to EventBus. Handles its own respawn timer.
class_name Enemy
extends CharacterBody3D

@export var def: EnemyDef

var stats: Stats
var display_name: String = "Enemy"
var spawn_position: Vector3
var facing: int = Facing.DOWN
var _target: Node = null  ## who this enemy is attacking (for BASIC_ATTACK intents)
var _nav_target := Vector3.INF
var _knockback := Vector3.ZERO

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: BillboardSprite = $Sprite
@onready var ai: Node = $AI
@onready var shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	add_to_group("enemy")
	axis_lock_linear_y = true
	spawn_position = global_position
	agent.path_desired_distance = 0.6
	agent.target_desired_distance = 0.5
	if def:
		display_name = def.display_name
		stats = Stats.from_enemy(def)
		if def.sheet:
			sprite.apply_sheet(def.sheet)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.attack_started.connect(_on_attack_started)


func is_alive() -> bool:
	return stats != null and stats.is_alive()


func get_target() -> Node:
	return _target


func set_target(t: Node) -> void:
	_target = t


# --- movement requested by the AI ----------------------------------------------

## Sets a navigation destination (re-pathing only when it moved noticeably).
func navigate_to(point: Vector3) -> void:
	if _nav_target == Vector3.INF or _nav_target.distance_to(point) > 0.5:
		_nav_target = point
		agent.target_position = point


func stop_navigation() -> void:
	_nav_target = Vector3.INF
	velocity = Vector3.ZERO


func navigation_finished() -> bool:
	return _nav_target == Vector3.INF or agent.is_navigation_finished()


## Called by CombatSystem: an impulse (units/s) that decays over ~0.3 s.
func apply_knockback(impulse: Vector3) -> void:
	_knockback = impulse
	_knockback.y = 0.0


## Moves one physics step along the current path. Call from the AI each tick.
func step_navigation() -> void:
	var dir := Vector3.ZERO
	if _knockback.length() > 0.2:
		velocity = _knockback
		_knockback = _knockback.move_toward(Vector3.ZERO, 30.0 * get_physics_process_delta_time())
		move_and_slide()
		global_position.y = 0.0
		return
	if _nav_target != Vector3.INF and not agent.is_navigation_finished():
		var to := agent.get_next_path_position() - global_position
		to.y = 0.0
		if to.length() > 0.02:
			dir = to.normalized()
	velocity = dir * stats.move_speed
	move_and_slide()
	global_position.y = 0.0


func face_towards(point: Vector3) -> void:
	var d := Vector2(point.x - global_position.x, point.z - global_position.z)
	if d.length_squared() > 0.001:
		facing = Facing.from_vector(d)


func update_sprite() -> void:
	var planar := Vector2(velocity.x, velocity.z)
	if planar.length() > 0.2:
		facing = Facing.from_vector(planar)
		sprite.play_anim(&"walk", facing)
	else:
		sprite.play_anim(&"idle", facing)


# --- reactions ---------------------------------------------------------------

func _on_attack_started(attacker: Node, target: Node) -> void:
	if attacker == self:
		face_towards(target.global_position)
		sprite.play_anim(&"attack", facing, true)


func _on_damage_dealt(result: Dictionary) -> void:
	if result.target == self and is_alive():
		sprite.flash()
		sprite.play_anim(&"hit", facing, true)


func _on_entity_died(entity: Node, _killer: Node) -> void:
	if entity != self:
		return
	velocity = Vector3.ZERO
	stop_navigation()
	_target = null
	shape.set_deferred("disabled", true)
	ai.set_physics_process(false)
	sprite.play_anim(&"death", facing)
	get_tree().create_timer(1.4).timeout.connect(func() -> void: visible = false)
	get_tree().create_timer(def.respawn_seconds if def else 8.0).timeout.connect(respawn)


func respawn() -> void:
	_knockback = Vector3.ZERO
	stats = Stats.from_enemy(def)
	global_position = spawn_position
	velocity = Vector3.ZERO
	visible = true
	shape.set_deferred("disabled", false)
	sprite.reset()
	GameRules.instance.combat.reset_attacker(self)
	ai.reset()
	ai.set_physics_process(true)

## Player
## The player's body in the world. It executes movement intents handed over by
## GameRules, approaches and auto-attacks its current target (by submitting
## BASIC_ATTACK intents; CombatSystem decides if a swing happens), and drives
## its sprite. No input is read here and no damage math happens here.
class_name Player
extends CharacterBody3D

signal facing_changed(facing: int)
signal target_changed(target: Node)

const TARGET_REPATH := 0.25

@export var class_def: ClassDef

var stats: Stats
var display_name: String = "You"
var facing: int = Facing.DOWN
var target: Node = null

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: BillboardSprite = $Sprite

var _dir_input: Vector2 = Vector2.ZERO
var _nav_active := false
var _stuck_time := 0.0
var _target_repath := 0.0
var _dead := false


func _ready() -> void:
	axis_lock_linear_y = true
	agent.path_desired_distance = 0.6
	agent.target_desired_distance = 0.4
	agent.path_max_distance = 3.0
	add_to_group("player")
	if class_def:
		display_name = class_def.display_name
		stats = Stats.from_class(class_def, GameState.level)
		if class_def.sheet:
			sprite.apply_sheet(class_def.sheet)
	else:
		stats = Stats.new()
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.attack_started.connect(_on_attack_started)


func is_alive() -> bool:
	return not _dead and stats != null and stats.is_alive()


func get_target() -> Node:
	return target


# --- intents -------------------------------------------------------------------

func apply_move_intent(intent: Intent) -> void:
	if _dead:
		return
	match intent.type:
		Intent.Type.MOVE_TO:
			_dir_input = Vector2.ZERO
			_nav_active = true
			_stuck_time = 0.0
			agent.target_position = intent.position
			set_target(null)
		Intent.Type.MOVE_DIR:
			_dir_input = intent.direction
			if _dir_input != Vector2.ZERO:
				_nav_active = false
				set_target(null)
		Intent.Type.STOP:
			_dir_input = Vector2.ZERO
			_nav_active = false


func set_target(t: Node) -> void:
	if t != null and (not is_instance_valid(t) or not t.is_alive()):
		t = null
	if t == target:
		return
	var was_approaching := target != null
	target = t
	_target_repath = 0.0
	if target or was_approaching:
		_nav_active = false  # drop any approach path when the target changes
	target_changed.emit(target)
	EventBus.target_changed.emit(target)


# --- simulation ---------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _dead:
		return
	var dir := Vector3.ZERO
	var attacking := false
	if _dir_input != Vector2.ZERO:
		dir = Vector3(_dir_input.x, 0.0, _dir_input.y)
	elif target != null:
		if not is_instance_valid(target) or not target.is_alive():
			set_target(null)
		else:
			var dist := CombatSystem.planar_distance(self, target)
			if dist <= stats.attack_range:
				_nav_active = false
				_face_point(target.global_position)
				attacking = true
				GameRules.instance.submit(Intent.basic_attack(self))
			else:
				_target_repath -= delta
				if _target_repath <= 0.0:
					_target_repath = TARGET_REPATH
					agent.target_position = target.global_position
					_nav_active = true
	if dir == Vector3.ZERO and _nav_active and not attacking:
		if agent.is_navigation_finished():
			_nav_active = false
		else:
			var to := agent.get_next_path_position() - global_position
			to.y = 0.0
			if to.length() > 0.02:
				dir = to.normalized()
	velocity = dir * stats.move_speed
	move_and_slide()
	global_position.y = 0.0
	# Give up on a path we cannot make progress on (blocked by a prop).
	if _nav_active and target == null:
		if get_real_velocity().length() < 0.3:
			_stuck_time += delta
			if _stuck_time > 0.6:
				_nav_active = false
		else:
			_stuck_time = 0.0
	_update_sprite()


func _face_point(p: Vector3) -> void:
	var d := Vector2(p.x - global_position.x, p.z - global_position.z)
	if d.length_squared() > 0.001:
		var f := Facing.from_vector(d)
		if f != facing:
			facing = f
			facing_changed.emit(f)


func _update_sprite() -> void:
	var planar := Vector2(velocity.x, velocity.z)
	if planar.length() > 0.2:
		var f := Facing.from_vector(planar)
		if f != facing:
			facing = f
			facing_changed.emit(f)
		sprite.play_anim(&"walk", facing)
	else:
		sprite.play_anim(&"idle", facing)


# --- reactions (visual only) --------------------------------------------------

func _on_attack_started(attacker: Node, _target: Node) -> void:
	if attacker == self:
		sprite.play_anim(&"attack", facing, true)


func _on_damage_dealt(result: Dictionary) -> void:
	if result.target == self and is_alive():
		sprite.flash()
		sprite.play_anim(&"hit", facing, true)


func _on_entity_died(entity: Node, _killer: Node) -> void:
	if entity == target:
		set_target(null)
	if entity == self:
		_dead = true
		velocity = Vector3.ZERO
		_dir_input = Vector2.ZERO
		_nav_active = false
		sprite.play_anim(&"death", facing)
		EventBus.player_died.emit()
		get_tree().create_timer(1.6).timeout.connect(GameRules.instance.respawn_player)


func respawn(at: Vector3) -> void:
	stats = Stats.from_class(class_def, GameState.level) if class_def else Stats.new()
	global_position = at
	velocity = Vector3.ZERO
	_dead = false
	set_target(null)
	sprite.reset()
	GameRules.instance.combat.reset_attacker(self)
	EventBus.player_respawned.emit()

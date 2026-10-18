## Player
## The player's body in the world. It executes movement intents handed over by
## GameRules (tap-to-move via NavigationAgent3D, or a direction from joystick /
## keyboard) and drives its sprite's walk/idle animation and facing.
## No input is read here and no combat math happens here.
class_name Player
extends CharacterBody3D

signal facing_changed(facing: int)

@export var move_speed: float = 5.0

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: BillboardSprite = $Sprite

var facing: int = Facing.DOWN
var _dir_input: Vector2 = Vector2.ZERO
var _nav_active := false
var _stuck_time := 0.0


func _ready() -> void:
	axis_lock_linear_y = true
	agent.path_desired_distance = 0.6
	agent.target_desired_distance = 0.4
	agent.path_max_distance = 3.0
	add_to_group("player")


func apply_move_intent(intent: Intent) -> void:
	match intent.type:
		Intent.Type.MOVE_TO:
			_dir_input = Vector2.ZERO
			_nav_active = true
			_stuck_time = 0.0
			agent.target_position = intent.position
		Intent.Type.MOVE_DIR:
			_dir_input = intent.direction
			if _dir_input != Vector2.ZERO:
				_nav_active = false
		Intent.Type.STOP:
			_dir_input = Vector2.ZERO
			_nav_active = false


func is_moving() -> bool:
	return velocity.length_squared() > 0.04


func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	if _dir_input != Vector2.ZERO:
		dir = Vector3(_dir_input.x, 0.0, _dir_input.y)
	elif _nav_active:
		if agent.is_navigation_finished():
			_nav_active = false
		else:
			var next := agent.get_next_path_position()
			var to := next - global_position
			to.y = 0.0
			if to.length() > 0.02:
				dir = to.normalized()
	velocity = dir * move_speed
	move_and_slide()
	global_position.y = 0.0
	# Give up on a path we cannot make progress on (blocked by a prop).
	if _nav_active:
		if get_real_velocity().length() < 0.3:
			_stuck_time += delta
			if _stuck_time > 0.6:
				_nav_active = false
		else:
			_stuck_time = 0.0
	_update_sprite()


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

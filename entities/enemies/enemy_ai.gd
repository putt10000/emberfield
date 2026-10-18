## EnemyAI
## State machine for an enemy: idle -> wander -> chase -> attack -> return (leash)
## -> dead. It only decides where the body should go and when to request an
## attack (as an intent through GameRules). It never deals damage itself.
class_name EnemyAI
extends Node

enum State { IDLE, WANDER, CHASE, ATTACK, RETURN, DEAD }

const REPATH_INTERVAL := 0.3
const SAFE_ZONE_RADIUS := 5.5

@onready var enemy: Enemy = get_parent()

var state: State = State.IDLE
var _timer := 0.0
var _repath := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_timer = _rng.randf_range(0.5, 2.0)


func reset() -> void:
	state = State.IDLE
	_timer = _rng.randf_range(0.5, 2.0)


func _physics_process(delta: float) -> void:
	if enemy.def == null or not enemy.is_alive():
		state = State.DEAD
		return
	var player: Node3D = GameRules.instance.player if GameRules.instance else null
	var player_ok: bool = player != null and is_instance_valid(player) and player.is_alive()
	var dist_player := CombatSystem.planar_distance(enemy, player) if player_ok else INF
	var dist_spawn := CombatSystem.planar_distance_to(enemy.global_position, enemy.spawn_position)
	var player_in_safe_zone: bool = player_ok and CombatSystem.planar_distance_to(player.global_position, GameState.town_spawn_position) < SAFE_ZONE_RADIUS
	var can_aggro: bool = player_ok and not player_in_safe_zone and dist_player <= enemy.def.aggro_range
	_timer -= delta
	_repath -= delta

	match state:
		State.IDLE:
			enemy.stop_navigation()
			if can_aggro:
				_enter_chase(player)
			elif _timer <= 0.0:
				var ang := _rng.randf_range(0.0, TAU)
				var r := _rng.randf_range(1.0, enemy.def.wander_radius)
				enemy.navigate_to(enemy.spawn_position + Vector3(cos(ang) * r, 0.0, sin(ang) * r))
				_timer = 4.0
				state = State.WANDER
		State.WANDER:
			if can_aggro:
				_enter_chase(player)
			elif enemy.navigation_finished() or _timer <= 0.0:
				enemy.stop_navigation()
				_timer = _rng.randf_range(1.5, 3.5)
				state = State.IDLE
		State.CHASE:
			if not player_ok or player_in_safe_zone or dist_spawn > enemy.def.leash_range:
				_enter_return()
			elif dist_player <= enemy.stats.attack_range:
				enemy.stop_navigation()
				state = State.ATTACK
			elif _repath <= 0.0:
				_repath = REPATH_INTERVAL
				enemy.navigate_to(player.global_position)
		State.ATTACK:
			if not player_ok or player_in_safe_zone:
				_enter_return()
			elif dist_player > enemy.stats.attack_range * 1.25:
				_enter_chase(player)
			else:
				enemy.face_towards(player.global_position)
				enemy.set_target(player)
				GameRules.instance.submit(Intent.basic_attack(enemy))
		State.RETURN:
			if dist_spawn < 0.8 or enemy.navigation_finished():
				enemy.stop_navigation()
				enemy.stats.hp = enemy.stats.max_hp  # classic leash heal
				_timer = _rng.randf_range(1.0, 2.0)
				state = State.IDLE
			elif _repath <= 0.0:
				_repath = REPATH_INTERVAL
				enemy.navigate_to(enemy.spawn_position)
		State.DEAD:
			pass

	enemy.step_navigation()
	enemy.update_sprite()


func _enter_chase(player: Node3D) -> void:
	state = State.CHASE
	_repath = 0.0
	enemy.set_target(player)
	enemy.navigate_to(player.global_position)


func _enter_return() -> void:
	state = State.RETURN
	_repath = 0.0
	enemy.set_target(null)
	enemy.navigate_to(enemy.spawn_position)

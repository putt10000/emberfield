## Scripted scenario test: drives the real game with intents and asserts on
## game state. Covers targeting, auto-attack, enemy retaliation, enemy death +
## respawn, and player death + respawn. main.gd adds this node when the game is
## started with the user argument --sim-test (autoloads exist that way):
##   godot --headless --path . -- --sim-test
## (tools/run_tests.sh runs it as its second step.)
extends Node

var _failures: Array[String] = []
var _damage_log: Array[Dictionary] = []


func _ready() -> void:
	_run()


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		_failures.append(msg)
		printerr("  FAIL ", msg)


func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


## Waits up to max_seconds (simulated) for predicate() to become true.
func _wait_until(predicate: Callable, max_seconds: float) -> bool:
	var frames := int(max_seconds * Engine.physics_ticks_per_second)
	for i in frames:
		if predicate.call():
			return true
		await get_tree().physics_frame
	return predicate.call()


func _run() -> void:
	EventBus.damage_dealt.connect(func(r: Dictionary) -> void: _damage_log.append(r))
	# The field bakes its nav mesh and spawns enemies a few idle frames after load.
	for i in 120:
		await get_tree().process_frame
		if get_tree().get_nodes_in_group("enemy").size() > 0:
			break
	await _wait_frames(5)

	var rules: GameRules = GameRules.instance
	var player: Player = rules.player
	_check(player != null and player.is_alive(), "player spawned alive")
	var enemies := get_tree().get_nodes_in_group("enemy")
	_check(enemies.size() == 6, "6 enemies spawned (got %d)" % enemies.size())
	var enemy: Enemy = enemies[0]
	_check(enemy.stats.hp == 40, "mossblob starts at 40 hp")

	# --- Tap-to-move through the real input path ---------------------------
	var input: InputController = get_node("../InputController")
	var cam: Camera3D = input.camera
	var start := player.global_position
	var goal := start + Vector3(4.0, 0.0, 0.0)
	var screen := cam.unproject_position(goal)
	input._pending_tap = screen
	await _wait_frames(2)
	_check(player._nav_active, "ground tap starts navigation (tap at %s)" % screen)
	var moved: bool = await _wait_until(func() -> bool:
		return player.global_position.distance_to(goal) < 0.8, 4.0)
	_check(moved, "player reaches the tapped point (at %s, wanted %s)" % [player.global_position, goal])

	# --- Tap on an enemy through the real input path ------------------------
	player.global_position = enemy.global_position + Vector3(-3.0, 0.0, 0.0)
	rules.submit(Intent.stop())
	await _wait_frames(90)  # let the camera settle after the teleport
	var enemy_screen := cam.unproject_position(enemy.global_position + Vector3(0.0, 0.6, 0.0))
	input._pending_tap = enemy_screen
	await _wait_frames(2)
	_check(player.get_target() == enemy, "tapping an enemy on screen targets it (tap at %s)" % enemy_screen)
	rules.submit(Intent.attack_target(null))
	rules.submit(Intent.stop())
	await _wait_frames(60)
	# Fat-finger pick: a tap beside the body still selects it (same frame, so nothing moved).
	var body_screen := cam.unproject_position(enemy.global_position + Vector3(0.0, 0.7, 0.0))
	_check(input._pick_enemy(body_screen + Vector2(70.0, 0.0)) == enemy, "tap 70 px beside the enemy still picks it")
	_check(input._pick_enemy(body_screen + Vector2(300.0, 0.0)) == null, "tap far from any enemy picks nothing")
	input._pending_tap = body_screen + Vector2(60.0, 0.0)
	await _wait_frames(2)
	_check(player.get_target() == enemy, "near-miss tap targets the enemy through the intent path")

	# --- Targeting + auto-attack -----------------------------------------
	rules.submit(Intent.attack_target(enemy))
	_check(player.get_target() == enemy, "attack_target intent selects the enemy")
	var approached: bool = await _wait_until(func() -> bool:
		return CombatSystem.planar_distance(player, enemy) <= player.stats.attack_range + 0.05, 4.0)
	_check(approached, "player walks into attack range")
	var dead: bool = await _wait_until(func() -> bool: return not enemy.is_alive(), 12.0)
	_check(dead, "enemy dies from auto-attacks within 12 s")
	var player_hits := _damage_log.filter(func(r: Dictionary) -> bool: return r.source == player)
	var enemy_hits := _damage_log.filter(func(r: Dictionary) -> bool: return r.source == enemy)
	_check(player_hits.size() >= 3, "player landed several hits (%d)" % player_hits.size())
	var in_range := true
	for r in player_hits:
		var hi := 20 if r.is_crit else 13
		if r.amount < 10 or r.amount > hi:
			in_range = false
	_check(in_range, "player hit amounts within 10..13 (crit up to 20)")
	_check(enemy_hits.size() >= 1, "enemy fought back (%d hits)" % enemy_hits.size())
	_check(player.stats.hp < player.stats.max_hp, "player lost hp")
	_check(player.get_target() == null, "target cleared when the enemy died")

	# --- Enemy respawn ----------------------------------------------------
	var hidden: bool = await _wait_until(func() -> bool: return not enemy.visible, 3.0)
	_check(hidden, "dead enemy hides after the death animation")
	var respawned: bool = await _wait_until(func() -> bool: return enemy.is_alive() and enemy.visible, 10.0)
	_check(respawned, "enemy respawns within its timer")
	_check(enemy.stats.hp == enemy.stats.max_hp, "respawned enemy has full hp")
	_check(enemy.global_position.distance_to(enemy.spawn_position) < 0.5, "respawned at its spawn point")

	# --- Player death + respawn -------------------------------------------
	player.stats.hp = 1
	player.global_position = enemy.global_position + Vector3(1.0, 0.0, 0.0)
	var player_died: bool = await _wait_until(func() -> bool: return not player.is_alive(), 8.0)
	_check(player_died, "enemy kills a 1-hp player")
	var player_back: bool = await _wait_until(func() -> bool: return player.is_alive(), 4.0)
	_check(player_back, "player respawns")
	_check(player.stats.hp == player.stats.max_hp, "player respawns with full hp")
	_check(player.global_position.distance_to(GameState.town_spawn_position) < 0.5, "player respawns at town")

	print("----\nscenario: %d checks failed" % _failures.size())
	get_tree().quit(1 if _failures.size() > 0 else 0)

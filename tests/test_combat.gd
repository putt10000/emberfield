## Combat math tests (CombatSystem.compute_damage, Stats growth).
extends "res://tests/lib/test_case.gd"

# Loaded by path (not class_name) so the headless runner never depends on the
# editor's class cache being fresh.
var CombatSystem = load("res://core/combat_system.gd")
var StatsScript = load("res://core/stats.gd")
var ClassDefScript = load("res://core/defs/class_def.gd")
var EnemyDefScript = load("res://core/defs/enemy_def.gd")


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func test_damage_stays_within_variance_without_crit() -> void:
	for i in 200:
		var d: Dictionary = CombatSystem.compute_damage(20, 4, 1.0, 0.0, _rng(i))
		# base = 20 - 2 = 18, +-10% -> 16..20 after rounding
		assert_between(d.amount, 16, 20, "seed %d" % i)
		assert_true(not d.is_crit, "no crit at 0 rate")


func test_damage_never_below_one() -> void:
	var d: Dictionary = CombatSystem.compute_damage(1, 500, 1.0, 0.0, _rng(3))
	assert_eq(d.amount, 1)


func test_crit_always_at_full_rate_and_scales() -> void:
	for i in 50:
		var d: Dictionary = CombatSystem.compute_damage(20, 4, 1.0, 1.0, _rng(i))
		assert_true(d.is_crit, "crit at rate 1.0")
		# 18 * 1.5 = 27, +-10% -> 24..30
		assert_between(d.amount, 24, 30, "seed %d" % i)


func test_crit_rate_is_roughly_respected() -> void:
	var crits := 0
	var n := 2000
	var r := _rng(42)
	for i in n:
		if CombatSystem.compute_damage(10, 0, 1.0, 0.25, r).is_crit:
			crits += 1
	assert_between(float(crits) / n, 0.20, 0.30, "crit frequency")


func test_skill_multiplier_applies_before_defence() -> void:
	var d: Dictionary = CombatSystem.compute_damage(10, 10, 2.0, 0.0, _rng(1))
	# 10*2 - 5 = 15 -> 13..17
	assert_between(d.amount, 13, 17)


func test_stats_from_class_grow_per_level() -> void:
	var cd = ClassDefScript.new()
	cd.max_hp = 100
	cd.hp_per_level = 12
	cd.atk = 12
	cd.atk_per_level = 2
	var s1 = StatsScript.from_class(cd, 1)
	var s5 = StatsScript.from_class(cd, 5)
	assert_eq(s1.max_hp, 100)
	assert_eq(s5.max_hp, 148)
	assert_eq(s5.atk, 20)
	assert_eq(s5.hp, s5.max_hp, "spawns at full hp")


func test_stats_from_enemy_copy_values() -> void:
	var ed = EnemyDefScript.new()
	ed.max_hp = 40
	ed.atk = 6
	var s = StatsScript.from_enemy(ed)
	assert_eq(s.hp, 40)
	assert_eq(s.atk, 6)
	assert_true(s.is_alive())
	s.hp = 0
	assert_true(not s.is_alive())

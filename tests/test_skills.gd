## Skill gating rules (CombatSystem.skill_blocker) — pure, no scene needed.
extends "res://tests/lib/test_case.gd"

var CombatSystem = load("res://core/combat_system.gd")
var StatsScript = load("res://core/stats.gd")
var SkillDefScript = load("res://core/defs/skill_def.gd")


func _skill(kind: int, cost: int, range_: float) -> Resource:
	var s = SkillDefScript.new()
	s.kind = kind
	s.sp_cost = cost
	s.range = range_
	return s


func _stats(sp: int) -> RefCounted:
	var st = StatsScript.new()
	st.max_sp = 30
	st.sp = sp
	return st


func test_cooldown_blocks() -> void:
	var r = CombatSystem.skill_blocker(_stats(30), _skill(0, 10, 2.0), 15.0, 10.0, true, 1.0)
	assert_eq(r, &"cooldown")


func test_sp_blocks_after_cooldown() -> void:
	var r = CombatSystem.skill_blocker(_stats(5), _skill(0, 10, 2.0), 0.0, 10.0, true, 1.0)
	assert_eq(r, &"no_sp")


func test_strike_needs_target_in_range() -> void:
	assert_eq(CombatSystem.skill_blocker(_stats(30), _skill(0, 10, 2.0), 0.0, 10.0, false, INF), &"no_target")
	assert_eq(CombatSystem.skill_blocker(_stats(30), _skill(0, 10, 2.0), 0.0, 10.0, true, 3.5), &"out_of_range")
	assert_eq(CombatSystem.skill_blocker(_stats(30), _skill(0, 10, 2.0), 0.0, 10.0, true, 1.9), &"")


func test_aoe_dash_heal_need_no_target() -> void:
	for kind in [1, 2, 3]:
		assert_eq(CombatSystem.skill_blocker(_stats(30), _skill(kind, 10, 0.0), 0.0, 10.0, false, INF), &"", "kind %d" % kind)


func test_exact_sp_is_enough() -> void:
	assert_eq(CombatSystem.skill_blocker(_stats(10), _skill(3, 10, 0.0), 0.0, 1.0, false, INF), &"")

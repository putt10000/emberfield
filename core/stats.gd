## Stats
## Runtime combat numbers for one entity. Built from a ClassDef (+ level) or an
## EnemyDef. Only CombatSystem / Progression change hp, sp and the rest.
class_name Stats
extends RefCounted

var max_hp: int = 1
var hp: int = 1
var max_sp: int = 0
var sp: int = 0
var atk: int = 1
var def: int = 0
var attack_speed: float = 1.0
var move_speed: float = 3.0
var crit_rate: float = 0.0
var attack_range: float = 1.5
var hit_delay: float = 0.2


static func from_class(cd: ClassDef, level: int) -> Stats:
	var s := Stats.new()
	var l := maxi(level, 1) - 1
	s.max_hp = cd.max_hp + cd.hp_per_level * l
	s.max_sp = cd.max_sp + cd.sp_per_level * l
	s.atk = cd.atk + cd.atk_per_level * l
	s.def = cd.def + cd.def_per_level * l
	s.hp = s.max_hp
	s.sp = s.max_sp
	s.attack_speed = cd.attack_speed
	s.move_speed = cd.move_speed
	s.crit_rate = cd.crit_rate
	s.attack_range = cd.attack_range
	s.hit_delay = cd.hit_delay
	return s


static func from_enemy(ed: EnemyDef) -> Stats:
	var s := Stats.new()
	s.max_hp = ed.max_hp
	s.hp = ed.max_hp
	s.atk = ed.atk
	s.def = ed.def
	s.attack_speed = ed.attack_speed
	s.move_speed = ed.move_speed
	s.crit_rate = ed.crit_rate
	s.attack_range = ed.attack_range
	s.hit_delay = ed.hit_delay
	return s


func is_alive() -> bool:
	return hp > 0


func hp_ratio() -> float:
	return float(hp) / float(maxi(max_hp, 1))


func sp_ratio() -> float:
	return float(sp) / float(maxi(max_sp, 1))


func restore_full() -> void:
	hp = max_hp
	sp = max_sp

## ClassDef
## Data for a playable class: base stats at level 1 and growth per level.
## Instances live in data/classes/*.tres. No logic here.
class_name ClassDef
extends Resource

@export var id: StringName = &"swordfighter"
@export var display_name: String = "Swordfighter"
@export var sheet: SpriteSheetDef

@export_group("Base stats (level 1)")
@export var max_hp: int = 100
@export var max_sp: int = 30
@export var atk: int = 12
@export var def: int = 4
@export var attack_speed: float = 1.2  ## attacks per second
@export var move_speed: float = 5.0
@export var crit_rate: float = 0.10
@export var attack_range: float = 1.6
@export var hit_delay: float = 0.15  ## seconds from attack start to damage

@export_group("Growth per level")
@export var hp_per_level: int = 12
@export var sp_per_level: int = 4
@export var atk_per_level: int = 2
@export var def_per_level: int = 1

@export_group("Skills (Milestone 4)")
@export var skill_ids: Array[StringName] = []

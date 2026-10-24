## SkillDef
## Data for one active skill (used from Milestone 4). Instances in data/skills/*.tres.
class_name SkillDef
extends Resource

enum Kind { STRIKE, AOE, DASH, HEAL }

@export var id: StringName = &"cleave"
@export var display_name: String = "Cleave"
## 2-4 letters shown on the action-bar button until icons exist.
@export var short_name: String = "CLV"
@export var kind: Kind = Kind.STRIKE
@export var sp_cost: int = 12
@export var cooldown: float = 6.0
## Multiplier on ATK for damaging skills; fraction of max HP for HEAL.
@export var power: float = 2.2
@export var range: float = 1.8
## AOE radius / DASH distance.
@export var radius: float = 2.5
## STRIKE: knockback impulse (units/s). DASH: damage radius at the end of the dash.
@export var knockback: float = 0.0
@export_multiline var description: String = ""

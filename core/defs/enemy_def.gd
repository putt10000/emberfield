## EnemyDef
## Data for one enemy type. Instances live in data/enemies/*.tres.
class_name EnemyDef
extends Resource

enum Behavior { MELEE, RANGED }

@export var id: StringName = &"mossblob"
@export var display_name: String = "Mossblob"
@export var sheet: SpriteSheetDef
@export var behavior: Behavior = Behavior.MELEE

@export_group("Stats")
@export var max_hp: int = 40
@export var atk: int = 6
@export var def: int = 1
@export var attack_speed: float = 0.8
@export var move_speed: float = 2.2
@export var crit_rate: float = 0.02
@export var attack_range: float = 1.3
@export var hit_delay: float = 0.35

@export_group("Behaviour")
@export var aggro_range: float = 6.0
@export var leash_range: float = 14.0
@export var wander_radius: float = 4.0
## RANGED only: preferred distance to keep from the player.
@export var preferred_range: float = 6.0
@export var projectile_scene: PackedScene

@export_group("Rewards")
@export var exp_reward: int = 8
@export var loot_table: LootTable
@export var respawn_seconds: float = 8.0

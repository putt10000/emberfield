## LootTable
## Drop rules for an enemy (used from Milestone 5). Instances in data/loot/*.tres.
class_name LootTable
extends Resource

@export var coins_min: int = 1
@export var coins_max: int = 4
## 0..1 chance that one potion drops.
@export var potion_chance: float = 0.25

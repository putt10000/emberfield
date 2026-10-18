## Torch — warm point light with a cheap flicker. No shadows (expensive on web).
extends Node3D

@onready var _light: OmniLight3D = $Light
var _base_energy: float
var _seed: float = randf() * 100.0


func _ready() -> void:
	_base_energy = _light.light_energy


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 + _seed
	var n := sin(t * 9.0) * 0.5 + sin(t * 23.0) * 0.3 + sin(t * 5.3) * 0.2
	_light.light_energy = _base_energy * (1.0 + n * 0.12)

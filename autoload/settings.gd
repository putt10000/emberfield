## Settings (autoload)
## Persisted player preferences, saved to user://settings.cfg (IndexedDB on web).
## Read with get_value(key); write with set_value(key, value), which also saves
## and broadcasts EventBus.setting_changed.
extends Node

const PATH := "user://settings.cfg"
const SECTION := "settings"

enum MovementMode { TAP_TO_MOVE = 0, JOYSTICK = 1 }

## Every known setting with its default. Adding a setting = adding a line here.
const DEFAULTS := {
	"movement_mode": MovementMode.TAP_TO_MOVE,
	"show_debug": false,
	"shadows": true,
	"glow": true,
}

var _values: Dictionary = {}


func _ready() -> void:
	_values = DEFAULTS.duplicate()
	load_settings()


func get_value(key: String) -> Variant:
	return _values.get(key, DEFAULTS.get(key))


func set_value(key: String, value: Variant) -> void:
	if _values.has(key) and _values[key] == value:
		return
	_values[key] = value
	save_settings()
	EventBus.setting_changed.emit(key, value)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return  # First run: keep defaults.
	for key in DEFAULTS.keys():
		_values[key] = cfg.get_value(SECTION, key, DEFAULTS[key])


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in _values.keys():
		cfg.set_value(SECTION, key, _values[key])
	var err := cfg.save(PATH)
	if err != OK:
		push_warning("Settings: could not save (%s)" % error_string(err))

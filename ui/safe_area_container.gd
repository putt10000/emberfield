## SafeAreaContainer
## A full-rect MarginContainer whose margins follow the device safe-area insets.
## Put all HUD / touch controls inside one of these so nothing hides under a
## notch or the home indicator. Re-measures whenever the window size changes.
class_name SafeAreaContainer
extends MarginContainer

## Extra padding (logical px) added on every side beyond the safe area.
@export var padding: int = 8


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_apply)
	_apply()
	# Browsers report insets a frame late after rotation; re-check shortly after.
	get_tree().create_timer(0.3).timeout.connect(_apply)


func _apply() -> void:
	var i := DeviceInfo.get_safe_insets()
	add_theme_constant_override("margin_left", int(i[0]) + padding)
	add_theme_constant_override("margin_top", int(i[1]) + padding)
	add_theme_constant_override("margin_right", int(i[2]) + padding)
	add_theme_constant_override("margin_bottom", int(i[3]) + padding)

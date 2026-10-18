## SettingsMenu
## Pauses the game and edits persisted Settings. Opened by the HUD menu button
## or the "settings" action (Esc). Buttons are thumb-sized (>= 64 px tall).
extends CanvasLayer

@onready var tap_btn: Button = %TapBtn
@onready var joy_btn: Button = %JoyBtn
@onready var shadows_btn: CheckButton = %ShadowsBtn
@onready var glow_btn: CheckButton = %GlowBtn
@onready var fps_btn: CheckButton = %FpsBtn
@onready var close_btn: Button = %CloseBtn


func _ready() -> void:
	visible = false
	tap_btn.pressed.connect(func() -> void: _set_mode(Settings.MovementMode.TAP_TO_MOVE))
	joy_btn.pressed.connect(func() -> void: _set_mode(Settings.MovementMode.JOYSTICK))
	shadows_btn.toggled.connect(func(on: bool) -> void: Settings.set_value("shadows", on))
	glow_btn.toggled.connect(func(on: bool) -> void: Settings.set_value("glow", on))
	fps_btn.toggled.connect(func(on: bool) -> void: Settings.set_value("show_debug", on))
	close_btn.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("settings"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	_refresh()
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false


func _set_mode(mode: int) -> void:
	Settings.set_value("movement_mode", mode)
	_refresh()


func _refresh() -> void:
	var mode := int(Settings.get_value("movement_mode"))
	tap_btn.button_pressed = mode == Settings.MovementMode.TAP_TO_MOVE
	joy_btn.button_pressed = mode == Settings.MovementMode.JOYSTICK
	shadows_btn.set_pressed_no_signal(bool(Settings.get_value("shadows")))
	glow_btn.set_pressed_no_signal(bool(Settings.get_value("glow")))
	fps_btn.set_pressed_no_signal(bool(Settings.get_value("show_debug")))

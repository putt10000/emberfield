## HUD
## Always-on controls inside the safe area: the floating joystick zone and the
## menu button. Bars, action bar and target info are added in later milestones.
extends CanvasLayer

signal menu_requested

@onready var joystick: TouchJoystick = %Joystick
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	menu_button.pressed.connect(func() -> void: menu_requested.emit())

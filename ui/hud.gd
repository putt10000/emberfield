## HUD
## Always-on controls inside the safe area: the floating joystick zone, the menu
## button, the player's frame (level, HP, SP) and the target frame. Presentation
## only: reads stats every frame, never changes them.
extends CanvasLayer

signal menu_requested

@onready var joystick: TouchJoystick = %Joystick
@onready var menu_button: Button = %MenuButton
@onready var name_label: Label = %NameLabel
@onready var hp_bar: ProgressBar = %HpBar
@onready var sp_bar: ProgressBar = %SpBar
@onready var target_frame: Control = %TargetFrame
@onready var target_name: Label = %TargetName
@onready var target_hp: ProgressBar = %TargetHp
@onready var action_bar: Control = %ActionBar

var _player: Node = null
var _target: Node = null


func _ready() -> void:
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	EventBus.player_spawned.connect(func(p: Node) -> void: _player = p)
	EventBus.target_changed.connect(_on_target_changed)
	target_frame.visible = false


func _on_target_changed(t: Node) -> void:
	_target = t
	target_frame.visible = t != null


func _process(_delta: float) -> void:
	if _player and is_instance_valid(_player) and _player.stats:
		var s: Stats = _player.stats
		name_label.text = "Lv %d  %s" % [GameState.level, _player.display_name]
		hp_bar.max_value = s.max_hp
		hp_bar.value = s.hp
		sp_bar.max_value = maxi(s.max_sp, 1)
		sp_bar.value = s.sp
	if _target and is_instance_valid(_target) and _target.is_alive():
		var ts: Stats = _target.stats
		target_name.text = _target.display_name
		target_hp.max_value = ts.max_hp
		target_hp.value = ts.hp
	elif target_frame.visible:
		target_frame.visible = false

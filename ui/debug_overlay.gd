## DebugOverlay
## Shows FPS, draw calls and renderer info. Toggle with the small corner button
## or the debug_toggle action (F3). Visibility is persisted in Settings.
extends CanvasLayer

@onready var _panel: PanelContainer = %Panel
@onready var _label: Label = %Readout
@onready var _toggle: Button = %Toggle

var _accum := 0.0


func _ready() -> void:
	_panel.visible = Settings.get_value("show_debug")
	_toggle.pressed.connect(_on_toggle)
	EventBus.setting_changed.connect(_on_setting_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		_on_toggle()
		get_viewport().set_input_as_handled()


func _on_toggle() -> void:
	Settings.set_value("show_debug", not _panel.visible)


func _on_setting_changed(key: String, value: Variant) -> void:
	if key == "show_debug":
		_panel.visible = value


func _process(delta: float) -> void:
	if not _panel.visible:
		return
	_accum += delta
	if _accum < 0.25:
		return
	_accum = 0.0
	var vis := get_viewport().get_visible_rect().size
	var win := DisplayServer.window_get_size()
	_label.text = "FPS %d\nDraw calls %d\nObjects %d\nPrimitives %.1fk\nMem %.1f MB\n%s\n%s\nView %dx%d  Win %dx%d" % [
		Performance.get_monitor(Performance.TIME_FPS),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0,
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		RenderingServer.get_current_rendering_method(),
		RenderingServer.get_video_adapter_name().left(40),
		vis.x, vis.y, win.x, win.y,
	]

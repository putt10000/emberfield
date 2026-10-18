## DebugOverlay
## Shows FPS, draw calls and renderer info. Toggle with the small corner button
## or the debug_toggle action (F3). Visibility is persisted in Settings.
extends CanvasLayer

@onready var _panel: PanelContainer = %Panel
@onready var _label: Label = %Readout
@onready var _toggle: Button = %Toggle

var _accum := 0.0
var _frames := 0


var _events: Array[String] = []


func _ready() -> void:
	_panel.visible = Settings.get_value("show_debug")
	_toggle.pressed.connect(_on_toggle)
	EventBus.setting_changed.connect(_on_setting_changed)
	# Short event log: makes combat observable without a debugger.
	EventBus.target_changed.connect(func(t: Node) -> void: _log("target: %s" % (t.name if t else "none")))
	EventBus.attack_started.connect(func(a: Node, t: Node) -> void: _log("%s swings at %s" % [a.name, t.name]))
	EventBus.damage_dealt.connect(func(r: Dictionary) -> void:
		_log("%s hits %s for %d%s" % [r.source.name, r.target.name, r.amount, "!" if r.is_crit else ""]))
	EventBus.entity_died.connect(func(e: Node, k: Node) -> void: _log("%s died (%s)" % [e.name, k.name if k else "?"]))
	EventBus.player_respawned.connect(func() -> void: _log("player respawned"))


func _log(line: String) -> void:
	_events.append(line)
	if _events.size() > 6:
		_events.pop_front()


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
	_frames += 1
	if _accum < 0.25:
		return
	var delta_ms := _accum / _frames * 1000.0
	_accum = 0.0
	_frames = 0
	var vis := get_viewport().get_visible_rect().size
	var win := DisplayServer.window_get_size()
	_label.text = "FPS %d  frame %.1f ms\nDraw calls %d  Objects %d\nPrimitives %.1fk\nCPU process %.1f ms  physics %.1f ms\nnav %.2f ms  Mem %.1f MB\n%s\n%s\nView %dx%d  Win %dx%d" % [
		Performance.get_monitor(Performance.TIME_FPS),
		delta_ms,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		RenderingServer.get_current_rendering_method(),
		RenderingServer.get_video_adapter_name().left(40),
		vis.x, vis.y, win.x, win.y,
	]
	if not _events.is_empty():
		_label.text += "\n--\n" + "\n".join(_events)

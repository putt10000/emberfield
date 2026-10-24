## SkillButton
## Round thumb-sized button for one skill: short name, SP cost, and a radial
## cooldown overlay with the seconds left. Pure presentation: it is told the
## cooldown fraction / affordability each frame and only emits a press.
class_name SkillButton
extends Button

var skill: SkillDef
var cooldown_fraction := 0.0  ## 1 = just used, 0 = ready
var cooldown_left := 0.0
var affordable := true

var _fail_tween: Tween
var _cost_label: Label


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	var r := int(minf(size.x, size.y) * 0.5)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.08, 0.14, 0.82) if state != "pressed" else Color(0.9, 0.6, 0.25, 0.9)
		sb.border_color = Color(0.95, 0.72, 0.35, 1.0)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(r)
		add_theme_stylebox_override(state, sb)
	add_theme_font_size_override("font_size", 18 if size.x < 90 else 24)
	add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	add_theme_color_override("font_pressed_color", Color(0.15, 0.1, 0.05))
	if skill:
		text = skill.short_name
		_cost_label = Label.new()
		_cost_label.text = "%d SP" % skill.sp_cost
		_cost_label.add_theme_font_size_override("font_size", 12)
		_cost_label.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
		_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_cost_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		_cost_label.offset_top = -20
		_cost_label.offset_bottom = -6
		_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_cost_label)
	EventBus.skill_failed.connect(_on_skill_failed)


func _process(_delta: float) -> void:
	modulate = Color(1, 1, 1, 1) if affordable or cooldown_fraction > 0.0 else Color(0.6, 0.6, 0.7, 0.8)
	queue_redraw()


func _draw() -> void:
	if cooldown_fraction <= 0.0:
		return
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	# Dark pie from 12 o'clock, clockwise, covering the remaining fraction.
	var pts := PackedVector2Array([c])
	var steps := 28
	var start := -PI / 2.0
	for i in steps + 1:
		var a := start + TAU * cooldown_fraction * float(i) / float(steps)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, Color(0, 0, 0, 0.6))
	var secs := "%.1f" % cooldown_left if cooldown_left < 10.0 else str(int(cooldown_left))
	var font := get_theme_default_font()
	var fs := 22
	var w := font.get_string_size(secs, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(font, Vector2(c.x - w * 0.5, c.y + fs * 0.35), secs, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(1, 1, 1))


func _on_skill_failed(skill_id: StringName, _reason: StringName) -> void:
	if skill == null or skill_id != skill.id:
		return
	if _fail_tween:
		_fail_tween.kill()
	var base := position
	_fail_tween = create_tween()
	for i in 3:
		_fail_tween.tween_property(self, "position:x", base.x + (4.0 if i % 2 == 0 else -4.0), 0.04)
	_fail_tween.tween_property(self, "position:x", base.x, 0.04)

## SafeAreaFrame (Milestone 1 test widget)
## Draws a bright border exactly on the safe-area edge and prints the measured
## insets, so on a phone you can confirm nothing important sits under the notch.
## This widget is replaced by the real HUD in Milestone 2.
extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	get_viewport().size_changed.connect(queue_redraw)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(1.0, 0.75, 0.3, 0.9), false, 3.0)
	var i := DeviceInfo.get_safe_insets()
	var vis := get_viewport().get_visible_rect().size
	var info := "Emberfield  ·  Milestone 1 pipeline test\nOrange frame = safe area. Insets L %d  T %d  R %d  B %d\nLogical viewport %d x %d   touch: %s   web: %s" % [
		int(i[0]), int(i[1]), int(i[2]), int(i[3]), int(vis.x), int(vis.y),
		"yes" if DeviceInfo.has_touch() else "no", "yes" if DeviceInfo.is_web else "no"]
	var font := ThemeDB.fallback_font
	draw_multiline_string(font, Vector2(16, size.y - 64), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, -1, Color(1, 1, 1, 0.95))

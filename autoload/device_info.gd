## DeviceInfo (autoload)
## Platform facts the UI needs: are we on web, is there a touchscreen, and
## how big are the safe-area insets (phone notches / home bar).
##
## Insets are returned in LOGICAL viewport pixels (the 1280x720 design space,
## widened by the "expand" stretch), so UI code can use them as margins directly.
extends Node

var is_web: bool = OS.has_feature("web")
var is_mobile: bool = OS.has_feature("mobile")

## JS snippet that reads the CSS env() insets exposed by web/head_include.html
## as custom properties, plus the CSS viewport width for scaling.
const _JS_INSETS := """(function(){
	var s = getComputedStyle(document.documentElement);
	function p(v){ var n = parseFloat(v); return isNaN(n) ? 0 : n; }
	return [p(s.getPropertyValue('--sal')), p(s.getPropertyValue('--sat')),
			p(s.getPropertyValue('--sar')), p(s.getPropertyValue('--sab')),
			window.innerWidth].join(',');
})()"""


func has_touch() -> bool:
	return DisplayServer.is_touchscreen_available()


func is_portrait() -> bool:
	var s := get_viewport().get_visible_rect().size
	return s.y > s.x


## Returns [left, top, right, bottom] insets in logical viewport pixels.
func get_safe_insets() -> Array[float]:
	var visible: Vector2 = get_viewport().get_visible_rect().size
	if is_web:
		return _web_insets(visible)
	return _native_insets(visible)


func _web_insets(visible: Vector2) -> Array[float]:
	var raw: Variant = JavaScriptBridge.eval(_JS_INSETS, true)
	if raw is String and not (raw as String).is_empty():
		var parts: PackedStringArray = (raw as String).split(",")
		if parts.size() == 5:
			var inner_w := float(parts[4])
			if inner_w > 0.0:
				# CSS px -> logical px: both describe the same physical width.
				var k := visible.x / inner_w
				return [float(parts[0]) * k, float(parts[1]) * k, float(parts[2]) * k, float(parts[3]) * k]
	return [0.0, 0.0, 0.0, 0.0]


func _native_insets(visible: Vector2) -> Array[float]:
	var win_size := Vector2(DisplayServer.window_get_size())
	if win_size.x <= 0.0 or win_size.y <= 0.0:
		return [0.0, 0.0, 0.0, 0.0]
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var win_pos := Vector2(DisplayServer.window_get_position())
	var k := visible.x / win_size.x
	var left: float = maxf(0.0, safe.position.x - win_pos.x) * k
	var top: float = maxf(0.0, safe.position.y - win_pos.y) * k
	var right: float = maxf(0.0, (win_pos.x + win_size.x) - safe.end.x) * k
	var bottom: float = maxf(0.0, (win_pos.y + win_size.y) - safe.end.y) * k
	# Desktop windows sit inside the safe area already; clamp absurd values.
	if not is_mobile:
		return [0.0, 0.0, 0.0, 0.0]
	return [left, top, right, bottom]

## Placeholder sprite-sheet generator (chibi style: big head, large eyes,
## three-tone shading, soft dark outline). Run with tools/gen_sprites.sh.
## Writes art/sprites/<name>.png in the layout described in art/sprites/README.md.
## Real art replaces these PNGs 1:1 (same layout, 48x48 frames).
extends SceneTree

const FRAME := 48
const COLS := 6
const ANIMS := [["idle", 2], ["walk", 6], ["attack", 4], ["hit", 2], ["death", 4]]
const DOWN := 0
const LEFT := 1
const RIGHT := 2
const UP := 3
const OUTLINE := Color(0.13, 0.08, 0.17, 1.0)
const FEET_Y := 46  # last body row is FEET_Y - 1


func _initialize() -> void:
	_make_sheet("res://art/sprites/player.png", _draw_hero, {
		"skin": Color(0.98, 0.85, 0.72), "hair": Color(0.55, 0.3, 0.16), "iris": Color(0.25, 0.45, 0.85),
		"tunic": Color(0.3, 0.5, 0.82), "pants": Color(0.28, 0.26, 0.38), "boots": Color(0.45, 0.28, 0.16),
		"belt": Color(0.4, 0.25, 0.14), "buckle": Color(0.95, 0.8, 0.35), "pad": Color(0.75, 0.76, 0.82),
		"blade": Color(0.82, 0.86, 0.95), "hilt": Color(0.5, 0.33, 0.16), "guard": Color(0.9, 0.75, 0.3),
	})
	_make_sheet("res://art/sprites/mossblob.png", _draw_jelly, {
		"body": Color(0.5, 0.75, 0.35), "moss": Color(0.25, 0.45, 0.2), "sprout": Color(0.35, 0.65, 0.3),
		"eye": Color(1, 1, 1), "pupil": Color(0.12, 0.1, 0.14), "cheek": Color(0.95, 0.55, 0.55),
	})
	print("Placeholder sprites written to art/sprites/")
	quit()


func _make_sheet(path: String, drawer: Callable, pal: Dictionary) -> void:
	var rows := ANIMS.size() * 4
	var sheet := Image.create(COLS * FRAME, rows * FRAME, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	var row := 0
	for anim in ANIMS:
		for dir in 4:
			for f in int(anim[1]):
				var frame := Image.create(FRAME, FRAME, false, Image.FORMAT_RGBA8)
				frame.fill(Color(0, 0, 0, 0))
				drawer.call(frame, String(anim[0]), dir, f, pal)
				_outline(frame)
				sheet.blit_rect(frame, Rect2i(0, 0, FRAME, FRAME), Vector2i(f * FRAME, row * FRAME))
			row += 1
	var err := sheet.save_png(path)
	if err != OK:
		push_error("Could not save %s (%s)" % [path, error_string(err)])
	else:
		print("  wrote ", path, " (", sheet.get_width(), "x", sheet.get_height(), ")")


# --- colour + drawing helpers ------------------------------------------------

func _light(c: Color) -> Color:
	return Color.from_hsv(c.h, c.s * 0.8, minf(c.v * 1.25, 1.0), c.a)


func _dark(c: Color) -> Color:
	return Color.from_hsv(c.h, minf(c.s * 1.15, 1.0), c.v * 0.68, c.a)


func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	if w <= 0 or h <= 0:
		return
	img.fill_rect(Rect2i(x, y, w, h), c)


func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


## Filled ellipse with a light band top-left and a shadow band bottom-right.
func _shaded_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, base: Color, shade: bool = true) -> void:
	var light := _light(base)
	var dark := _dark(base)
	for y in img.get_height():
		for x in img.get_width():
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			var d := dx * dx + dy * dy
			if d > 1.0:
				continue
			var c := base
			if shade:
				var diag := dx * 0.6 + dy * 0.8
				if diag < -0.55 and d > 0.25:
					c = light
				elif diag > 0.55 or d > 0.78:
					c = dark
			img.set_pixel(x, y, c)


## Rectangle with a light left column and a dark right column + bottom row.
func _shaded_rect(img: Image, x: int, y: int, w: int, h: int, base: Color) -> void:
	_rect(img, x, y, w, h, base)
	_rect(img, x, y, 2, h - 1, _light(base))
	_rect(img, x + w - 2, y + 1, 2, h - 1, _dark(base))
	_rect(img, x, y + h - 1, w, 1, _dark(base))


func _outline(img: Image) -> void:
	var src := img.duplicate() as Image
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.0:
				continue
			var near := false
			for off: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = Vector2i(x, y) + off
				if n.x >= 0 and n.y >= 0 and n.x < w and n.y < h and src.get_pixel(n.x, n.y).a > 0.0:
					near = true
					break
			if near:
				img.set_pixel(x, y, OUTLINE)


func _tint(img: Image, t: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				var m := c.lerp(Color(t.r, t.g, t.b, c.a), t.a)
				m.a = c.a
				img.set_pixel(x, y, m)


func _fade(img: Image, alpha: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				c.a *= alpha
				img.set_pixel(x, y, c)


func _eye(img: Image, x: int, y: int, iris: Color, pal: Dictionary, look: int = 0) -> void:
	# 3 wide x 4 tall: white, iris on the lower rows, pupil, highlight.
	_rect(img, x, y, 3, 4, Color(1, 1, 1))
	_rect(img, x, y + 1, 3, 3, iris)
	_rect(img, x + 1 + look, y + 2, 1, 2, pal.get("pupil", Color(0.1, 0.08, 0.12)))
	_px(img, x + (0 if look >= 0 else 2), y + 1, Color(1, 1, 1))


# --- hero (chibi swordfighter) -----------------------------------------------

func _draw_hero(img: Image, anim: String, dir: int, f: int, pal: Dictionary) -> void:
	var dy := 0
	var lift_l := 0
	var lift_r := 0
	var swing := 0
	var tint := Color(1, 1, 1, 0)
	match anim:
		"idle":
			dy = 1 if f == 1 else 0
		"walk":
			lift_l = [0, 3, 1, 0, 0, 0][f]
			lift_r = [0, 0, 0, 0, 3, 1][f]
			swing = [0, -2, -1, 0, 2, 1][f]
			dy = 1 if (f == 1 or f == 4) else 0
		"hit":
			tint = Color(1.0, 0.35, 0.3, 0.55)
			dy = -1
		"death":
			if f == 0:
				tint = Color(1.0, 0.35, 0.3, 0.45)
			elif f == 1:
				dy = 4
			else:
				_draw_hero_lying(img, pal)
				if f == 3:
					_fade(img, 0.55)
				return
	if anim == "attack":
		_draw_sword(img, dir, f, pal, true)
	_draw_hero_body(img, dir, dy, lift_l, lift_r, swing, pal, anim == "attack")
	if anim == "attack":
		_draw_sword(img, dir, f, pal, false)
	if tint.a > 0.0:
		_tint(img, tint)


func _draw_hero_body(img: Image, dir: int, dy: int, lift_l: int, lift_r: int, swing: int, pal: Dictionary, attacking: bool) -> void:
	var skin: Color = pal["skin"]
	var hair: Color = pal["hair"]
	var tunic: Color = pal["tunic"]
	var pants: Color = pal["pants"]
	var boots: Color = pal["boots"]
	# Legs (feet rest on FEET_Y - 1).
	var leg_top := 36 + dy
	for leg in [[19, lift_l], [25, lift_r]]:
		var lx: int = leg[0]
		var lift: int = leg[1]
		var bottom := FEET_Y - lift
		_rect(img, lx, leg_top, 4, bottom - leg_top, pants)
		_rect(img, lx + 3, leg_top, 1, bottom - leg_top, _dark(pants))
		_rect(img, lx, bottom - 3, 4, 3, boots)
		_rect(img, lx, bottom - 1, 4, 1, _dark(boots))
	# Torso with belt and buckle.
	_shaded_rect(img, 16, 25 + dy, 16, 12, tunic)
	_rect(img, 16, 34 + dy, 16, 2, pal["belt"])
	_rect(img, 23, 34 + dy, 2, 2, pal["buckle"])
	# Shoulder pads.
	_shaded_rect(img, 14, 25 + dy, 4, 4, pal["pad"])
	_shaded_rect(img, 30, 25 + dy, 4, 4, pal["pad"])
	# Arms (sleeve + hand). Profile views show one arm in front.
	var arms: Array = [[14, swing], [31, -swing]]
	if dir == LEFT:
		arms = [[20, swing]]
	elif dir == RIGHT:
		arms = [[25, swing]]
	for a in arms:
		var ax: int = a[0]
		var ay: int = 29 + dy + int(a[1])
		_rect(img, ax, ay, 3, 4, tunic)
		_rect(img, ax, ay + 4, 3, 3, skin)
	# Head: big skin oval.
	var cy := 15.0 + dy
	_shaded_ellipse(img, 24.0, cy, 9.5, 9.5, skin)
	# Hair.
	if dir == UP:
		_shaded_ellipse(img, 24.0, cy - 0.5, 9.8, 10.0, hair)
	else:
		_shaded_ellipse(img, 24.0, cy - 4.0, 10.2, 7.0, hair)
		# Ragged bangs.
		for t in [[15, 3], [18, 5], [21, 3], [24, 6], [27, 3], [30, 5], [32, 2]]:
			_rect(img, int(t[0]), int(cy - 2.0), 2, int(t[1]), hair)
		if dir == LEFT:
			_rect(img, 30, int(cy - 3.0), 4, 11, hair)
			_rect(img, 32, int(cy - 3.0), 2, 11, _dark(hair))
		elif dir == RIGHT:
			_rect(img, 14, int(cy - 3.0), 4, 11, hair)
			_rect(img, 14, int(cy - 3.0), 2, 11, _dark(hair))
		else:
			_rect(img, 14, int(cy - 2.0), 2, 8, hair)
			_rect(img, 32, int(cy - 2.0), 2, 8, hair)
	# Face.
	var iris: Color = pal["iris"]
	var ey := int(cy) + 1
	match dir:
		DOWN:
			_eye(img, 19, ey, iris, pal)
			_eye(img, 27, ey, iris, pal)
			_px(img, 17, ey + 4, pal.get("cheek", Color(0.95, 0.6, 0.6)))
			_px(img, 31, ey + 4, pal.get("cheek", Color(0.95, 0.6, 0.6)))
			_px(img, 24, ey + 6, _dark(skin))
		LEFT:
			_eye(img, 17, ey, iris, pal, -1)
			_px(img, 15, ey + 6, _dark(skin))
		RIGHT:
			_eye(img, 29, ey, iris, pal, 1)
			_px(img, 33, ey + 6, _dark(skin))
	if attacking and dir != UP:
		# Determined brow line.
		if dir != RIGHT:
			_rect(img, 18, ey - 1, 4, 1, _dark(hair))
		if dir != LEFT:
			_rect(img, 27, ey - 1, 4, 1, _dark(hair))


func _draw_sword(img: Image, dir: int, f: int, pal: Dictionary, behind_pass: bool) -> void:
	var strike := (f == 1 or f == 2)
	var want_behind := (not strike) or dir == UP
	if want_behind != behind_pass:
		return
	var blade: Color = pal["blade"]
	var edge := Color(1, 1, 1)
	var hilt: Color = pal["hilt"]
	var guard: Color = pal["guard"]
	match dir:
		DOWN:
			if strike:
				_rect(img, 32, 28, 3, 17, blade)
				_rect(img, 32, 28, 1, 17, edge)
				_rect(img, 30, 26, 7, 2, guard)
				_rect(img, 32, 22, 3, 4, hilt)
			else:
				_rect(img, 34, 4, 3, 15, blade)
				_rect(img, 34, 4, 1, 15, edge)
				_rect(img, 32, 19, 7, 2, guard)
				_rect(img, 34, 21, 3, 4, hilt)
		UP:
			if strike:
				_rect(img, 12, 0, 3, 18, blade)
				_rect(img, 12, 0, 1, 18, edge)
				_rect(img, 10, 18, 7, 2, guard)
				_rect(img, 12, 20, 3, 4, hilt)
			else:
				_rect(img, 11, 14, 3, 14, blade)
				_rect(img, 9, 28, 7, 2, guard)
		LEFT:
			if strike:
				_rect(img, 0, 27, 18, 3, blade)
				_rect(img, 0, 27, 18, 1, edge)
				_rect(img, 18, 25, 2, 7, guard)
				_rect(img, 20, 27, 4, 3, hilt)
			else:
				_rect(img, 19, 4, 3, 16, blade)
				_rect(img, 19, 4, 1, 16, edge)
				_rect(img, 17, 20, 7, 2, guard)
		RIGHT:
			if strike:
				_rect(img, 30, 27, 18, 3, blade)
				_rect(img, 30, 27, 18, 1, edge)
				_rect(img, 28, 25, 2, 7, guard)
				_rect(img, 24, 27, 4, 3, hilt)
			else:
				_rect(img, 26, 4, 3, 16, blade)
				_rect(img, 26, 4, 1, 16, edge)
				_rect(img, 24, 20, 7, 2, guard)


func _draw_hero_lying(img: Image, pal: Dictionary) -> void:
	_rect(img, 4, 40, 8, 4, pal["pants"])
	_rect(img, 2, 40, 3, 4, pal["boots"])
	_shaded_rect(img, 12, 37, 18, 8, pal["tunic"])
	_shaded_ellipse(img, 36.0, 38.5, 8.0, 7.5, pal["skin"])
	_shaded_ellipse(img, 39.0, 35.0, 8.0, 6.0, pal["hair"])
	_rect(img, 33, 39, 2, 1, pal["pupil"] if pal.has("pupil") else OUTLINE)


# --- jelly (mossblob) ----------------------------------------------------------

func _draw_jelly(img: Image, anim: String, dir: int, f: int, pal: Dictionary) -> void:
	var rx := 15.0
	var ry := 11.0
	var ox := 0.0
	var tint := Color(1, 1, 1, 0)
	var face := true
	match anim:
		"idle":
			ry = 11.0 if f == 0 else 10.2
			rx = 15.0 if f == 0 else 15.6
		"walk":
			var sy: float = [1.0, 0.8, 1.2, 1.0, 0.8, 1.2][f]
			ry = 11.0 * sy
			rx = 15.0 / sqrt(sy)
		"attack":
			var push: float = [0.0, 4.0, 7.0, 3.0][f]
			var d := Vector2(0, 0.4)
			match dir:
				LEFT: d = Vector2(-1, 0)
				RIGHT: d = Vector2(1, 0)
				UP: d = Vector2(0, -0.4)
			ox = d.x * push
			rx = 15.0 + push * 0.5 * absf(d.x)
			ry = 11.0 - push * 0.35 + push * 0.5 * absf(d.y)
		"hit":
			tint = Color(1.0, 0.35, 0.3, 0.55)
			ry = 9.0
			rx = 16.5
		"death":
			if f == 0:
				tint = Color(1.0, 0.35, 0.3, 0.45)
			elif f == 1:
				ry = 6.0
				rx = 18.0
				face = false
			else:
				ry = 2.5
				rx = 21.0
				face = false
	var cy := 45.0 - ry
	var cx := 24.0 + ox
	var body: Color = pal["body"]
	_shaded_ellipse(img, cx, cy, rx, ry, body)
	# Glossy highlight and moss tufts.
	_shaded_ellipse(img, cx - rx * 0.42, cy - ry * 0.45, rx * 0.2, ry * 0.18, Color(1, 1, 1, 0.85), false)
	_px(img, int(cx - rx * 0.2), int(cy - ry * 0.7), Color(1, 1, 1, 0.9))
	if face:
		for m in [[-0.35, -0.72, 2.6, 1.4], [0.3, -0.8, 2.2, 1.2], [0.55, -0.1, 1.8, 1.1]]:
			_shaded_ellipse(img, cx + rx * m[0], cy + ry * m[1], m[2], m[3], pal["moss"], false)
		# Little sprout on top.
		var sx := int(cx)
		var sy := int(cy - ry) - 1
		_rect(img, sx, sy - 3, 1, 3, pal["sprout"])
		_rect(img, sx - 2, sy - 4, 2, 2, pal["sprout"])
		_rect(img, sx + 1, sy - 5, 2, 2, pal["sprout"])
	if face and dir != UP:
		var ey := int(cy - ry * 0.25)
		var e1 := int(cx) - 7
		var e2 := int(cx) + 3
		var look := 0
		if dir == LEFT:
			e1 = int(cx) - 11
			e2 = int(cx) - 5
			look = -1
		elif dir == RIGHT:
			e1 = int(cx) + 2
			e2 = int(cx) + 8
			look = 1
		for ex in [e1, e2]:
			_rect(img, ex, ey, 4, 5, pal["eye"])
			_rect(img, ex + 1 + look, ey + 1, 2, 3, pal["pupil"])
			_px(img, ex + (0 if look >= 0 else 3), ey + 1, Color(1, 1, 1))
		var cheek: Color = pal["cheek"]
		if dir == DOWN:
			_rect(img, e1 - 3, ey + 4, 2, 1, cheek)
			_rect(img, e2 + 5, ey + 4, 2, 1, cheek)
			_rect(img, int(cx) - 1, ey + 6, 2, 1, _dark(body))
		elif dir == LEFT:
			_rect(img, e1 - 3, ey + 4, 2, 1, cheek)
		else:
			_rect(img, e2 + 5, ey + 4, 2, 1, cheek)
	if anim == "death" and f == 3:
		_fade(img, 0.5)
	if tint.a > 0.0:
		_tint(img, tint)

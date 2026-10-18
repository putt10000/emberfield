## Placeholder sprite-sheet generator. Run once (or whenever you change it):
##   tools/gen_sprites.sh      (= godot --headless --path . -s tools/gen_placeholder_sprites.gd)
## Writes art/sprites/<name>.png in the layout described in art/sprites/README.md
## and entities/shared/sprite_sheet_def.gd. Real art replaces these PNGs 1:1.
extends SceneTree

const FRAME := 32
const COLS := 6
const ANIMS := [["idle", 2], ["walk", 6], ["attack", 4], ["hit", 2], ["death", 4]]
const DOWN := 0
const LEFT := 1
const RIGHT := 2
const UP := 3
const OUTLINE := Color(0.08, 0.06, 0.1, 1.0)
const EYE := Color(0.1, 0.08, 0.12, 1.0)


func _initialize() -> void:
	_make_humanoid("res://art/sprites/player.png", {
		"skin": Color(0.95, 0.80, 0.66), "hair": Color(0.36, 0.2, 0.1),
		"tunic": Color(0.27, 0.47, 0.78), "belt": Color(0.35, 0.22, 0.12),
		"legs": Color(0.22, 0.2, 0.3), "boots": Color(0.3, 0.18, 0.1),
		"blade": Color(0.85, 0.88, 0.95), "hilt": Color(0.5, 0.35, 0.15),
	})
	print("Placeholder sprites written to art/sprites/")
	quit()


func _make_humanoid(path: String, pal: Dictionary) -> void:
	var rows := ANIMS.size() * 4
	var sheet := Image.create(COLS * FRAME, rows * FRAME, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	var row := 0
	for anim in ANIMS:
		for dir in 4:
			for f in int(anim[1]):
				var frame := Image.create(FRAME, FRAME, false, Image.FORMAT_RGBA8)
				frame.fill(Color(0, 0, 0, 0))
				_draw_humanoid(frame, String(anim[0]), dir, f, pal)
				_outline(frame)
				sheet.blit_rect(frame, Rect2i(0, 0, FRAME, FRAME), Vector2i(f * FRAME, row * FRAME))
			row += 1
	var err := sheet.save_png(path)
	if err != OK:
		push_error("Could not save %s (%s)" % [path, error_string(err)])
	else:
		print("  wrote ", path, " (", sheet.get_width(), "x", sheet.get_height(), ")")


# --- drawing helpers ---------------------------------------------------------

func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	if w <= 0 or h <= 0:
		return
	img.fill_rect(Rect2i(x, y, w, h), c)


func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


func _draw_humanoid(img: Image, anim: String, dir: int, f: int, pal: Dictionary) -> void:
	var dy := 0
	var lift_l := 0
	var lift_r := 0
	var tint := Color(1, 1, 1, 0)
	match anim:
		"idle":
			dy = 1 if f == 1 else 0
		"walk":
			lift_l = [0, 2, 1, 0, 0, 0][f]
			lift_r = [0, 0, 0, 0, 2, 1][f]
			dy = 1 if (f == 1 or f == 4) else 0
		"hit":
			tint = Color(1.0, 0.35, 0.3, 0.6)
			dy = -1
		"death":
			if f == 0:
				tint = Color(1.0, 0.35, 0.3, 0.5)
			elif f == 1:
				dy = 3
			else:
				_draw_lying(img, pal)
				if f == 3:
					_fade(img, 0.55)
				return
	if anim == "attack":
		_draw_sword(img, dir, f, pal, true)
	_draw_body(img, dir, dy, lift_l, lift_r, pal)
	if anim == "attack":
		_draw_sword(img, dir, f, pal, false)
	if tint.a > 0.0:
		_tint(img, tint)


func _draw_body(img: Image, dir: int, dy: int, lift_l: int, lift_r: int, pal: Dictionary) -> void:
	var legs: Color = pal["legs"]
	var boots: Color = pal["boots"]
	var tunic: Color = pal["tunic"]
	var skin: Color = pal["skin"]
	var hair: Color = pal["hair"]
	# Legs (feet rest on y = 29).
	var top := 24 + dy
	_rect(img, 12, top, 3, 30 - top - lift_l, legs)
	_rect(img, 12, 28 - lift_l, 3, 2, boots)
	_rect(img, 17, top, 3, 30 - top - lift_r, legs)
	_rect(img, 17, 28 - lift_r, 3, 2, boots)
	# Torso + belt.
	_rect(img, 11, 15 + dy, 10, 9, tunic)
	_rect(img, 11, 22 + dy, 10, 1, pal["belt"])
	# Arms.
	var arm_xs: Array = [9, 21]
	if dir == LEFT:
		arm_xs = [13]
	elif dir == RIGHT:
		arm_xs = [17]
	for ax in arm_xs:
		_rect(img, ax, 16 + dy, 2, 4, tunic)
		_rect(img, ax, 20 + dy, 2, 2, skin)
	# Head (rounded block).
	_rect(img, 12, 6 + dy, 8, 9, skin)
	_rect(img, 11, 7 + dy, 1, 7, skin)
	_rect(img, 20, 7 + dy, 1, 7, skin)
	# Hair.
	_rect(img, 11, 5 + dy, 10, 3, hair)
	_rect(img, 12, 4 + dy, 8, 1, hair)
	match dir:
		UP:
			_rect(img, 11, 8 + dy, 10, 5, hair)
		LEFT:
			_rect(img, 19, 8 + dy, 2, 4, hair)
		RIGHT:
			_rect(img, 11, 8 + dy, 2, 4, hair)
	# Eyes.
	match dir:
		DOWN:
			_px(img, 14, 10 + dy, EYE)
			_px(img, 18, 10 + dy, EYE)
		LEFT:
			_px(img, 13, 10 + dy, EYE)
		RIGHT:
			_px(img, 18, 10 + dy, EYE)


func _draw_sword(img: Image, dir: int, f: int, pal: Dictionary, behind_pass: bool) -> void:
	var strike := (f == 1 or f == 2)
	var want_behind := (not strike) or dir == UP
	if want_behind != behind_pass:
		return
	var blade: Color = pal["blade"]
	var hilt: Color = pal["hilt"]
	match dir:
		DOWN:
			if strike:
				_rect(img, 21, 19, 2, 11, blade)
				_rect(img, 20, 18, 4, 1, hilt)
			else:
				_rect(img, 22, 4, 2, 10, blade)
				_rect(img, 21, 14, 4, 1, hilt)
		UP:
			if strike:
				_rect(img, 9, 1, 2, 12, blade)
				_rect(img, 8, 13, 4, 1, hilt)
			else:
				_rect(img, 8, 10, 2, 10, blade)
		LEFT:
			if strike:
				_rect(img, 0, 17, 11, 2, blade)
				_rect(img, 11, 16, 1, 4, hilt)
			else:
				_rect(img, 13, 4, 2, 10, blade)
		RIGHT:
			if strike:
				_rect(img, 21, 17, 11, 2, blade)
				_rect(img, 20, 16, 1, 4, hilt)
			else:
				_rect(img, 17, 4, 2, 10, blade)


func _draw_lying(img: Image, pal: Dictionary) -> void:
	_rect(img, 3, 26, 5, 3, pal["legs"])
	_rect(img, 2, 26, 2, 3, pal["boots"])
	_rect(img, 8, 24, 16, 6, pal["tunic"])
	_rect(img, 24, 23, 6, 7, pal["skin"])
	_rect(img, 27, 22, 4, 4, pal["hair"])
	_px(img, 25, 26, EYE)


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

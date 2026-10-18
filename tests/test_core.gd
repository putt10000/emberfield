## Tests for the small pure helpers in core/.
extends "res://tests/lib/test_case.gd"


func test_facing_from_vector() -> void:
	var Facing := load("res://core/facing.gd")
	assert_eq(Facing.from_vector(Vector2(1, 0.2)), Facing.RIGHT)
	assert_eq(Facing.from_vector(Vector2(-1, 0.2)), Facing.LEFT)
	assert_eq(Facing.from_vector(Vector2(0.1, 1)), Facing.DOWN)
	assert_eq(Facing.from_vector(Vector2(0.1, -1)), Facing.UP)
	assert_eq(Facing.from_vector(Vector2.ZERO), Facing.DOWN)


func test_intent_move_dir_is_clamped() -> void:
	var Intent := load("res://core/intent.gd")
	var i = Intent.move_dir(Vector2(3, 4))
	assert_near(i.direction.length(), 1.0)
	assert_eq(i.type, Intent.Type.MOVE_DIR)


func test_sprite_sheet_builds_all_animations() -> void:
	var Def := load("res://entities/shared/sprite_sheet_def.gd")
	var def = Def.new()
	def.texture = PlaceholderTexture2D.new()
	var frames: SpriteFrames = def.build_frames()
	assert_eq(frames.get_animation_names().size(), 5 * 4)
	assert_eq(frames.get_frame_count(&"walk_left"), 6)
	assert_true(not frames.get_animation_loop(&"death_up"), "death should not loop")

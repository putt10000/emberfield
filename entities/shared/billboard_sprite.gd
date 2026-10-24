## BillboardSprite
## AnimatedSprite3D set up for HD-2D characters: upright Y-billboard, nearest
## filtering, alpha cut for correct depth sorting, lit by the scene. Builds its
## SpriteFrames from a SpriteSheetDef, so swapping the PNG swaps the look.
## Presentation only: it is told which animation and facing to show.
## One-shot animations (attack, hit) finish before locomotion resumes; death
## sticks on its last frame until reset() is called.
class_name BillboardSprite
extends AnimatedSprite3D

const ONE_SHOTS: Array[StringName] = [&"attack", &"hit"]

@export var sheet: SpriteSheetDef

var _current_anim: StringName = &""
var _current_facing: int = Facing.DOWN
var _oneshot_active := false
var _dead := false
var _pending_anim: StringName = &""
var _pending_facing: int = Facing.DOWN
var _flash_tween: Tween


func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	shaded = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if sheet:
		apply_sheet(sheet)
	animation_finished.connect(_on_animation_finished)
	play_anim(&"idle", Facing.DOWN, true)


func apply_sheet(new_sheet: SpriteSheetDef) -> void:
	sheet = new_sheet
	sprite_frames = sheet.build_frames()
	pixel_size = sheet.pixel_size
	# Feet on the node origin: shift the frame up by half its height (pixels).
	offset = Vector2(0.0, sheet.frame_size.y * 0.5)


## Plays "<anim>_<facing>". Locomotion (idle/walk) waits for a running one-shot;
## one-shots restart when restart is true; death overrides everything.
func play_anim(anim: StringName, facing: int, restart: bool = false) -> void:
	if sprite_frames == null:
		return
	if _dead and anim != &"death":
		return
	var full := StringName("%s_%s" % [anim, Facing.NAMES[facing]])
	if not sprite_frames.has_animation(full):
		return
	if anim == &"death":
		_dead = true
		_oneshot_active = false
		_play(anim, facing, full)
		return
	if anim in ONE_SHOTS:
		_oneshot_active = true
		_play(anim, facing, full)
		return
	if _oneshot_active:
		_pending_anim = anim
		_pending_facing = facing
		return
	if full == animation and is_playing() and not restart:
		return
	_play(anim, facing, full)


func _play(anim: StringName, facing: int, full: StringName) -> void:
	_current_anim = anim
	_current_facing = facing
	play(full)


func _on_animation_finished() -> void:
	if _oneshot_active:
		_oneshot_active = false
		if _pending_anim != &"":
			var a := _pending_anim
			_pending_anim = &""
			play_anim(a, _pending_facing)
		else:
			play_anim(&"idle", _current_facing)


## Brief white flash used when hit. HDR-bright so it blooms with glow on.
func flash() -> void:
	flash_color(Color(4.0, 4.0, 4.0, 1.0))


func flash_color(c: Color, seconds: float = 0.16) -> void:
	if _flash_tween:
		_flash_tween.kill()
	modulate = c
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color.WHITE, seconds)


func reset() -> void:
	_dead = false
	_oneshot_active = false
	_pending_anim = &""
	modulate = Color.WHITE
	play_anim(&"idle", Facing.DOWN, true)


func current_anim() -> StringName:
	return _current_anim

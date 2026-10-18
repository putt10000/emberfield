## BillboardSprite
## AnimatedSprite3D set up for HD-2D characters: upright Y-billboard, nearest
## filtering, alpha cut for correct depth sorting, lit by the scene. Builds its
## SpriteFrames from a SpriteSheetDef, so swapping the PNG swaps the look.
## Presentation only: it is told which animation and facing to show.
class_name BillboardSprite
extends AnimatedSprite3D

@export var sheet: SpriteSheetDef

var _current_anim: StringName = &""
var _current_facing: int = Facing.DOWN


func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	shaded = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if sheet:
		sprite_frames = sheet.build_frames()
		pixel_size = sheet.pixel_size
		# Feet on the node origin: shift the frame up by half its height (pixels).
		offset = Vector2(0.0, sheet.frame_size.y * 0.5)
	play_anim(&"idle", Facing.DOWN, true)


## Plays "<anim>_<facing>". Looping animations are not restarted when already
## playing; one-shots (attack/hit/death) restart when restart is true.
func play_anim(anim: StringName, facing: int, restart: bool = false) -> void:
	if sprite_frames == null:
		return
	var full := StringName("%s_%s" % [anim, Facing.NAMES[facing]])
	if not sprite_frames.has_animation(full):
		return
	if full == animation and is_playing() and not restart:
		return
	_current_anim = anim
	_current_facing = facing
	play(full)


func current_anim() -> StringName:
	return _current_anim

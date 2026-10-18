## SpriteSheetDef
## Describes how a character sprite sheet PNG is laid out, so real art can
## replace the placeholder by swapping the PNG (and editing numbers here).
##
## Layout: rows are animations in anim_order, 4 rows each (down, left, right, up),
## frames left to right. Unused cells at the end of a row are ignored.
class_name SpriteSheetDef
extends Resource

@export var texture: Texture2D
@export var frame_size: Vector2i = Vector2i(32, 32)
## World units per sprite pixel. 0.05 makes a 32 px frame 1.6 units tall.
@export var pixel_size: float = 0.05
@export var anim_order: Array[String] = ["idle", "walk", "attack", "hit", "death"]
## name -> { "frames": int, "fps": float, "loop": bool }
@export var animations: Dictionary = {
	"idle": {"frames": 2, "fps": 3.0, "loop": true},
	"walk": {"frames": 6, "fps": 10.0, "loop": true},
	"attack": {"frames": 4, "fps": 12.0, "loop": false},
	"hit": {"frames": 2, "fps": 10.0, "loop": false},
	"death": {"frames": 4, "fps": 6.0, "loop": false},
}


func build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation(&"default")
	var row := 0
	for anim in anim_order:
		var info: Dictionary = animations.get(anim, {})
		var count: int = int(info.get("frames", 1))
		for d in 4:
			var anim_name := StringName("%s_%s" % [anim, Facing.NAMES[d]])
			sf.add_animation(anim_name)
			sf.set_animation_speed(anim_name, float(info.get("fps", 6.0)))
			sf.set_animation_loop(anim_name, bool(info.get("loop", true)))
			for f in count:
				var at := AtlasTexture.new()
				at.atlas = texture
				at.region = Rect2(f * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)
				sf.add_frame(anim_name, at)
			row += 1
	return sf

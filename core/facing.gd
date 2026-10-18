## Facing
## Four-way facing shared by game logic and sprites. The camera has a fixed yaw
## looking along -Z, so world X is screen right and world +Z is screen down.
class_name Facing
extends RefCounted

enum { DOWN = 0, LEFT = 1, RIGHT = 2, UP = 3 }
const NAMES: Array[String] = ["down", "left", "right", "up"]


## v.x = world X, v.y = world Z. Returns DOWN for a zero vector.
static func from_vector(v: Vector2) -> int:
	if absf(v.x) > absf(v.y):
		return RIGHT if v.x > 0.0 else LEFT
	return DOWN if v.y >= 0.0 else UP


static func to_vector(f: int) -> Vector2:
	match f:
		LEFT: return Vector2(-1, 0)
		RIGHT: return Vector2(1, 0)
		UP: return Vector2(0, -1)
		_: return Vector2(0, 1)

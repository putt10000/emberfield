## RotateOverlay
## Full-screen prompt shown when the viewport is portrait. Browsers cannot lock
## orientation without fullscreen, so we ask the player to rotate instead.
extends CanvasLayer


func _ready() -> void:
	get_viewport().size_changed.connect(_update)
	_update()


func _update() -> void:
	visible = DeviceInfo.is_portrait()

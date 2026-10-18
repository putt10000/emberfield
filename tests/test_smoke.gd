## Smoke test: proves the runner and the project data load headlessly.
## Real combat-math tests arrive in Milestone 3.
extends "res://tests/lib/test_case.gd"


func test_runner_works() -> void:
	assert_eq(1 + 1, 2)


func test_project_settings_are_web_safe() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "gl_compatibility")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width")), 1280)
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_height")), 720)


func test_main_scene_loads() -> void:
	var scene: PackedScene = load("res://main.tscn")
	assert_true(scene != null, "main.tscn should load")

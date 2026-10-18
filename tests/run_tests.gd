## Test runner. Run with:  tools/run_tests.sh
## (= godot --headless --path . -s tests/run_tests.gd)
## Discovers tests/test_*.gd, runs every test_* method, exits 1 on failure.
extends SceneTree


func _initialize() -> void:
	var total := 0
	var failed := 0
	var dir := DirAccess.open("res://tests")
	var files: Array[String] = []
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			files.append(f)
	files.sort()
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		var case: RefCounted = script.new()
		var ran := 0
		for m in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			case.current_test = name
			case.call(name)
			ran += 1
		total += ran
		failed += case.failures.size()
		var mark := "PASS" if case.failures.is_empty() else "FAIL"
		print("[%s] %s (%d tests)" % [mark, f, ran])
		for msg in case.failures:
			printerr("       " + msg)
	print("----\n%d tests, %d failed" % [total, failed])
	quit(1 if failed > 0 else 0)

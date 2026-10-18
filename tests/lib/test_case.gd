## TestCase
## Minimal base class for headless tests. Subclass in tests/test_*.gd and add
## methods named test_*. No external addon needed.
# Referenced by path (extends "res://tests/lib/test_case.gd") so the headless
# runner works even before the editor has rebuilt its class-name cache.
extends RefCounted

var failures: Array[String] = []
var current_test: String = ""


func assert_true(cond: bool, msg: String = "expected true") -> void:
	if not cond:
		failures.append("%s: %s" % [current_test, msg])


func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s %s" % [current_test, str(expected), str(actual), msg])


func assert_near(actual: float, expected: float, eps: float = 0.001, msg: String = "") -> void:
	if absf(actual - expected) > eps:
		failures.append("%s: expected ~%s, got %s %s" % [current_test, str(expected), str(actual), msg])


func assert_between(value: float, lo: float, hi: float, msg: String = "") -> void:
	if value < lo or value > hi:
		failures.append("%s: %s not in [%s, %s] %s" % [current_test, str(value), str(lo), str(hi), msg])

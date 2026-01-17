extends "res://src/Scripts/Units/UnitBehavior.gd"

var original_atk_speed: float = 0.0

func on_skill_activated():
	unit.skill_active_timer = 5.0
	unit.set_highlight(true, Color.RED)
	original_atk_speed = unit.atk_speed
	unit.atk_speed *= 0.3

func on_skill_ended():
	unit.atk_speed = original_atk_speed

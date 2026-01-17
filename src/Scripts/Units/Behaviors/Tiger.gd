extends "res://src/Scripts/Units/DefaultBehavior.gd"

var skill_active_timer = 0.0
var _skill_interval_timer = 0.0

func on_tick(delta):
	if skill_active_timer > 0:
		skill_active_timer -= delta

		_skill_interval_timer -= delta
		if _skill_interval_timer <= 0:
			_skill_interval_timer = 0.2
			unit._spawn_meteor_at_random_enemy()

		if skill_active_timer <= 0:
			unit.set_highlight(false)

func on_skill_activated():
	skill_active_timer = unit.unit_data.get("skillDuration", 5.0)
	_skill_interval_timer = 0.0
	unit.set_highlight(true, Color.ORANGE)

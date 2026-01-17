extends "res://src/Scripts/Units/DefaultBehavior.gd"

var skill_active_timer: float = 0.0
var production_timer: float = 0.0
var max_production_timer: float = 5.0

func on_setup():
	production_timer = max_production_timer

func on_tick(delta):
	# Passive Heal
	production_timer -= delta
	if production_timer <= 0:
		GameManager.damage_core(-50)
		GameManager.spawn_floating_text(unit.global_position, "+50", Color.GREEN)
		production_timer = max_production_timer

	# Active Skill Regeneration
	if skill_active_timer > 0:
		skill_active_timer -= delta
		GameManager.damage_core(-200 * delta)

		if skill_active_timer <= 0:
			unit.set_highlight(false)

func on_skill_activated():
	skill_active_timer = 5.0
	unit.set_highlight(true, Color.GREEN)

extends DefaultBehavior
var aura_timer: float = 0.0
var skill_active_timer: float = 0.0

func on_tick(delta: float):
	# Passive Aura
	if unit.unit_data.has("skill") and unit.unit_data.skill == "milk_aura":
		aura_timer -= delta
		if aura_timer <= 0:
			GameManager.damage_core(-50)
			GameManager.spawn_floating_text(unit.global_position, "+50", Color.GREEN)
			aura_timer = 5.0

	# Active Skill Effect
	if skill_active_timer > 0:
		skill_active_timer -= delta
		GameManager.damage_core(-200 * delta)
		if skill_active_timer <= 0:
			unit.set_highlight(false)

func on_skill_activated():
	skill_active_timer = 5.0
	unit.set_highlight(true, Color.GREEN)

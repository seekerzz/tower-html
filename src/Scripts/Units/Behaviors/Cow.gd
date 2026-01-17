extends "res://src/Scripts/Units/UnitBehavior.gd"

func on_setup():
	if unit.unit_data.has("skill") and unit.unit_data.skill == "milk_aura":
		unit.max_production_timer = 5.0
		# Reset timer to new max if needed, though Unit.setup does it after reset_stats.
		# But Unit.setup calls reset_stats (which sets behavior?) then sets production_timer = max.
		# If behavior is set in setup, we need to ensure max_production_timer is set before production_timer init?
		# Step 3 says "In setup(key), dynamically load ...".
		# So behavior on_setup will be called.
		pass

func on_tick(delta: float):
	# Passive Logic
	if unit.unit_data.has("skill") and unit.unit_data.skill == "milk_aura":
		unit.production_timer -= delta
		if unit.production_timer <= 0:
			GameManager.damage_core(-50)
			GameManager.spawn_floating_text(unit.global_position, "+50", Color.GREEN)
			unit.production_timer = 5.0

	# Active Logic (Regeneration)
	if unit.skill_active_timer > 0:
		GameManager.damage_core(-200 * delta)

func on_skill_activated():
	unit.skill_active_timer = 5.0
	unit.set_highlight(true, Color.GREEN)

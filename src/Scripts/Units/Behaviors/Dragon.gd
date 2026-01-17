extends "res://src/Scripts/Units/UnitBehavior.gd"

func on_skill_execute_at(grid_pos: Vector2i):
	var extra_stats = {
		"duration": unit.unit_data.get("skillDuration", 8.0),
		"skillRadius": unit.unit_data.get("skillRadius", 150.0),
		"skillStrength": unit.unit_data.get("skillStrength", 3000.0),
		"skillColor": unit.unit_data.get("skillColor", "#330066"),
		"damage": 0,
		"hide_visuals": false
	}
	if GameManager.grid_manager:
		var world_pos = GameManager.grid_manager.get_world_pos_from_grid(grid_pos)
		if GameManager.combat_manager:
			GameManager.combat_manager.spawn_projectile(unit, world_pos, null, extra_stats)

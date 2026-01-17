extends DefaultBehavior

func on_skill_activated():
	if GameManager.grid_manager:
		GameManager.grid_manager.enter_skill_targeting(unit)

func on_skill_executed_at(grid_pos: Vector2i):
	GameManager.execute_skill_effect(unit.type_key, grid_pos)

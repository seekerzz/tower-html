extends DefaultBehavior

func on_point_skill(grid_pos: Vector2i):
	GameManager.execute_skill_effect("phoenix", grid_pos)

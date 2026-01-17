extends "res://src/Scripts/Units/UnitBehavior.gd"

func on_skill_execute_at(grid_pos: Vector2i):
	# Default behavior for point skills is to use the generic effect system
	GameManager.execute_skill_effect(unit.type_key, grid_pos)

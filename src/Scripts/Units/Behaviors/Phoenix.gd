extends "res://src/Scripts/Units/DefaultBehavior.gd"

func on_skill_executed_at(grid_pos: Vector2i):
	if !GameManager.grid_manager: return

	var world_pos = Vector2.ZERO
	var key = GameManager.grid_manager.get_tile_key(grid_pos.x, grid_pos.y)
	if GameManager.grid_manager.tiles.has(key):
		world_pos = GameManager.grid_manager.tiles[key].global_position
	else:
		var local_pos = Vector2(grid_pos.x * Constants.TILE_SIZE, grid_pos.y * Constants.TILE_SIZE)
		world_pos = GameManager.grid_manager.to_global(local_pos)

	var dmg = 15.0
	if Constants.UNIT_TYPES.has("phoenix"):
		dmg = Constants.UNIT_TYPES["phoenix"].get("damage", 30.0) * 0.5

	if GameManager.combat_manager:
		GameManager.combat_manager.start_meteor_shower(world_pos, dmg)

extends DefaultBehavior

func on_setup():
	if GameManager.grid_manager:
		GameManager.grid_manager.start_trap_placement_sequence(unit)

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	if randf() < 0.25:
		if GameManager.grid_manager:
			GameManager.grid_manager.try_spawn_trap(target.global_position, "fang")

func on_cleanup():
	if unit.associated_traps:
		for trap in unit.associated_traps:
			if is_instance_valid(trap):
				if GameManager.grid_manager:
					GameManager.grid_manager.remove_obstacle(trap)
				trap.queue_free()
		unit.associated_traps.clear()

func get_placement_trap_type() -> String:
	return "fang"

extends DefaultBehavior

# Toad Unit Behavior
# Support Unit: Places poison traps.
# L2: Max 2 traps.
# L3: Traps apply Distance Damage Debuff.

var max_traps: int = 1
var trap_duration: float = 25.0
var placed_traps: Array = []

func on_stats_updated():
	if unit.level >= 2:
		max_traps = 2
	else:
		max_traps = 1

func on_setup():
	pass

func on_skill_activated():
	if GameManager.grid_manager:
		GameManager.grid_manager.enter_skill_targeting(unit)

func on_skill_executed_at(grid_pos: Vector2i):
	# Calculate world position from grid position
	var world_pos = Vector2.ZERO
	if GameManager.grid_manager:
		world_pos = GameManager.grid_manager.get_world_pos_from_grid(grid_pos)

	if placed_traps.size() >= max_traps:
		var old_trap = placed_traps.pop_front()
		if is_instance_valid(old_trap):
			old_trap.queue_free()

	_place_trap(world_pos)

func _place_trap(pos: Vector2):
	var trap_scene = load("res://src/Scenes/Units/ToadTrap.tscn")
	if not trap_scene: return

	var trap = trap_scene.instantiate()
	trap.global_position = pos
	trap.duration = trap_duration
	trap.owner_toad = unit
	trap.level = unit.level

	unit.get_tree().current_scene.add_child(trap)
	placed_traps.append(trap)

	if trap.has_signal("trap_triggered"):
		trap.trap_triggered.connect(_on_trap_triggered)

func _on_trap_triggered(enemy, trap):
	if enemy.has_method("add_poison_stacks"):
		enemy.add_poison_stacks(2)

	if unit.level >= 3:
		_apply_distance_damage_debuff(enemy)

func _apply_distance_damage_debuff(enemy):
	var debuff_script = load("res://src/Scripts/Effects/DistanceDamageDebuff.gd")
	if debuff_script and enemy.has_method("apply_status"):
		enemy.apply_status(debuff_script, {"duration": 2.5, "tick_interval": 0.5, "source": unit})

func on_cleanup():
	for trap in placed_traps:
		if is_instance_valid(trap):
			trap.queue_free()
	placed_traps.clear()

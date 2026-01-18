extends "res://src/Scripts/CoreMechanics/CoreMechanic.gd"

# Internal class for damage source
class ViperTotemSource:
	var damage: float = 20.0
	var unit_data: Dictionary = { "damageType": "poison" }

	func calculate_damage_against(target):
		return damage

	func is_in_group(group_name):
		return false

func _ready():
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = false
	timer.autostart = true
	timer.connect("timeout", _on_timer_timeout)
	add_child(timer)

func _on_timer_timeout():
	# Ensure game is active
	if not GameManager.is_wave_active:
		return

	if not GameManager.grid_manager:
		return

	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return

	# Sort enemies by distance descending (furthest first)
	var core_pos = GameManager.grid_manager.global_position

	enemies.sort_custom(func(a, b):
		return a.global_position.distance_squared_to(core_pos) > b.global_position.distance_squared_to(core_pos)
	)

	# Take top 3
	var targets = []
	for i in range(min(enemies.size(), 3)):
		targets.append(enemies[i])

	for target in targets:
		if not is_instance_valid(target):
			continue

		var source = ViperTotemSource.new()
		var start_pos = core_pos # Logical start position

		var stats = {
			"is_meteor": true,
			"ground_pos": target.global_position,
			"damage": 20.0,
			"effects": {
				"poison": 5.0,
				"poison_stacks": 3
			},
			"source": source,
			"damageType": "poison"
		}

		GameManager.combat_manager.spawn_projectile(
			start_pos,
			target,
			20.0,
			1000.0, # Speed
			"ink", # visual
			stats
		)

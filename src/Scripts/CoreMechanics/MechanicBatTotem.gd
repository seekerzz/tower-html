extends "res://src/Scripts/CoreMechanics/CoreMechanic.gd"

var timer: Timer

func _ready():
	timer = Timer.new()
	timer.wait_time = 5.0
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

func _on_timer_timeout():
	if !GameManager.is_wave_active: return
	if !GameManager.combat_manager: return
	if !GameManager.grid_manager: return

	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0: return

	var core_pos = GameManager.grid_manager.global_position

	# Sort enemies by distance to core
	enemies.sort_custom(func(a, b):
		return a.global_position.distance_squared_to(core_pos) < b.global_position.distance_squared_to(core_pos)
	)

	# Take up to 3 closest
	var targets = []
	for i in range(min(enemies.size(), 3)):
		targets.append(enemies[i])

	if targets.size() > 0:
		print("[BatTotem] Firing at ", targets.size(), " enemies.")
		for target in targets:
			if is_instance_valid(target):
				var extra_stats = {
					"type": "bat_orb",
					"damage": 10.0,
					"speed": 400.0,
					"effects": { "bleed": 2.5 }
				}
				# Spawn projectile from Core position
				GameManager.combat_manager.spawn_projectile(
					self, # Source (Totem)
					core_pos, # Start Pos
					target, # Target
					extra_stats
				)

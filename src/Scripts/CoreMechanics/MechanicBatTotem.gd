extends "res://src/Scripts/CoreMechanics/CoreMechanic.gd"

class BatTotemSource:
	var damage: float = 20.0
	var unit_data: Dictionary = {
		"proj": "stinger",
		"damageType": "physical"
	}
	var crit_rate: float = 0.0
	var crit_dmg: float = 1.5

	func calculate_damage_against(_target):
		return damage

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
	if !GameManager.grid_manager: return

	var core_pos = GameManager.grid_manager.global_position
	var enemies = get_tree().get_nodes_in_group("enemies")

	if enemies.size() == 0:
		return

	# Sort by distance to core
	enemies.sort_custom(func(a, b):
		return a.global_position.distance_squared_to(core_pos) < b.global_position.distance_squared_to(core_pos)
	)

	var targets = enemies.slice(0, 3) # Get up to 3 nearest
	var source = BatTotemSource.new()

	for target in targets:
		if is_instance_valid(target):
			var stats = {
				"effects": {
					"bleed": 2.5
				},
				"damage": 20.0,
				"proj_override": "stinger"
			}
			GameManager.combat_manager.spawn_projectile(source, core_pos, target, stats)

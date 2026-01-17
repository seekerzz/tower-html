extends CoreMechanic

var timer: Timer
var damage: float = 50.0

class BatTotemSource extends RefCounted:
	var damage: float
	var unit_data: Dictionary
	var is_core: bool = true

	func _init(dmg, data):
		damage = dmg
		unit_data = data

	func calculate_damage_against(target):
		return damage

	func is_in_group(group):
		return false

func _ready():
	timer = Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()

func _on_timer_timeout():
	if !GameManager.is_wave_active: return
	if !GameManager.combat_manager: return

	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty(): return

	var core_pos = Vector2.ZERO
	if GameManager.grid_manager:
		core_pos = GameManager.grid_manager.global_position

	# Sort enemies by distance to core
	enemies.sort_custom(func(a, b):
		return a.global_position.distance_squared_to(core_pos) < b.global_position.distance_squared_to(core_pos)
	)

	var targets = enemies.slice(0, 3)

	# Virtual Source Object
	var source_data = {
		"proj": "stinger", # Visual style
		"damageType": "physical"
	}
	var source = BatTotemSource.new(damage, source_data)

	for target in targets:
		if !is_instance_valid(target): continue

		var extra_stats = {
			"effects": {
				"bleed": 2.5
			},
			"speed": 500.0,
			"pierce": 0
		}

		GameManager.combat_manager.spawn_projectile(source, core_pos, target, extra_stats)

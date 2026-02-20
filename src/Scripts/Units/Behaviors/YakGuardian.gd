extends "res://src/Scripts/Units/Behaviors/DefaultBehavior.gd"

var taunt_behavior: RefCounted
var taunt_radius: float = 120.0

func on_setup():
	var script = load("res://src/Scripts/Units/Behaviors/TauntBehavior.gd")
	if script:
		taunt_behavior = script.new(unit)
		taunt_behavior.taunt_interval = 6.0 if unit.level < 2 else 5.0
		# Sync radius if possible, but TauntBehavior has its own property.
		# We use our local taunt_radius for buff application.

	if unit.level >= 3:
		if not GameManager.is_connected("totem_attacked", _on_totem_attack):
			GameManager.totem_attacked.connect(_on_totem_attack)

func on_tick(delta: float):
	if taunt_behavior and taunt_behavior.has_method("on_tick"):
		taunt_behavior.on_tick(delta)

	# Apply guardian_shield buff to nearby allies
	if unit and GameManager.grid_manager:
		var range_sq = taunt_radius * taunt_radius
		for key in GameManager.grid_manager.tiles:
			var tile = GameManager.grid_manager.tiles[key]
			if tile.unit and tile.unit != unit and is_instance_valid(tile.unit):
				if unit.global_position.distance_squared_to(tile.unit.global_position) <= range_sq:
					tile.unit.apply_buff("guardian_shield", unit)

func get_damage_reduction() -> float:
	return 0.05

func _on_totem_attack(totem_type: String):
	if totem_type != "cow":
		return

	var bonus_damage = unit.max_hp * 0.15

	var enemies = []
	if GameManager.combat_manager:
		enemies = GameManager.combat_manager.get_enemies_in_range(unit.global_position, unit.range_val)

	for enemy in enemies:
		enemy.take_damage(bonus_damage, unit, "physical")
		unit.spawn_buff_effect("⚔️")

func on_cleanup():
	if GameManager.is_connected("totem_attacked", _on_totem_attack):
		GameManager.totem_attacked.disconnect(_on_totem_attack)

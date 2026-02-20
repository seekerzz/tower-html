extends "res://src/Scripts/Units/Behaviors/DefaultBehavior.gd"

var display_timer: float = 0.0
var display_interval: float = 5.0

func on_setup():
	display_timer = display_interval

func on_combat_tick(delta: float) -> bool:
	display_timer -= delta
	if display_timer <= 0:
		_trigger_display()
		display_timer = display_interval

	# Return false to allow normal attacks if configured in unit data
	return false

func _trigger_display():
	if not unit: return

	# Visual
	if unit.visual_holder:
		var tween = unit.create_tween()
		tween.tween_property(unit.visual_holder, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(unit.visual_holder, "scale", Vector2(1.0, 1.0), 0.2)

	GameManager.spawn_floating_text(unit.global_position, "Display!", Color.GOLD)

	# Logic
	var allies = _get_allies_in_range()
	var atk_bonus = 0.10
	if unit.level >= 2:
		atk_bonus = 0.20

	for ally in allies:
		if ally.has_method("add_temporary_buff"):
			# Duration matches interval (sustained effect)
			ally.add_temporary_buff("attack_speed", atk_bonus, display_interval)

			if unit.level >= 3:
				ally.add_temporary_buff("peacock_inspire", 1.0, display_interval)

			ally.play_buff_receive_anim()

func _get_allies_in_range() -> Array:
	var list = []
	if not GameManager.grid_manager: return list

	var my_pos = unit.global_position
	var r = unit.range_val

	var checked_units = []
	for key in GameManager.grid_manager.tiles:
		var tile = GameManager.grid_manager.tiles[key]
		var u = tile.unit
		if u and is_instance_valid(u) and not (u in checked_units):
			checked_units.append(u)
			# Include self or not? "Friendly units" usually implies all.
			if u.global_position.distance_to(my_pos) <= r:
				list.append(u)

	return list

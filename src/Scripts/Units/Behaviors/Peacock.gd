extends DefaultBehavior

var attack_counter: int = 0
var feather_refs: Array = []

func on_combat_tick(delta: float) -> bool:
	if unit.cooldown > 0: return true

	var combat_manager = GameManager.combat_manager
	if !combat_manager: return false

	var target = combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)

	if attack_counter >= 3:
		unit.cooldown = unit.atk_speed * GameManager.get_stat_modifier("attack_interval")
		attack_counter = 0

		if unit.visual_holder:
			var tween = unit.create_tween()
			tween.tween_property(unit.visual_holder, "scale", Vector2(1.3, 1.3), 0.1)
			tween.tween_property(unit.visual_holder, "scale", Vector2(1.0, 1.0), 0.1)

		for q in feather_refs:
			if is_instance_valid(q) and q.has_method("recall"):
				q.recall()
		feather_refs.clear()
		return true

	if target:
		unit._do_bow_attack(target, _spawn_feathers)
		return true

	return true

func _spawn_feathers(saved_target_pos: Vector2):
	var combat_manager = GameManager.combat_manager
	if !is_instance_valid(combat_manager): return

	# Determine if we use a target or just the position
	var target = combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)
	# _do_bow_attack passed saved_target_pos, which is good.

	var extra_shots = 0
	var multi_chance = 0.0

	if unit.unit_data.has("levels") and unit.unit_data["levels"].has(str(unit.level)):
		var mech = unit.unit_data["levels"][str(unit.level)].get("mechanics", {})
		multi_chance = mech.get("multi_shot_chance", 0.0)

	if multi_chance > 0.0 and randf() < multi_chance:
		extra_shots += 1

	var base_angle = (saved_target_pos - unit.global_position).angle()

	# Fire Primary Feather
	var proj_args = {}
	if target:
		pass
	else:
		proj_args["angle"] = base_angle
		proj_args["target_pos"] = saved_target_pos

	var proj = combat_manager.spawn_projectile(unit, unit.global_position, target, proj_args)
	if proj and is_instance_valid(proj):
		feather_refs.append(proj)

	# Fire Extra Shots
	if extra_shots > 0:
		var spread_angle = 0.2
		var angles = [base_angle - spread_angle, base_angle + spread_angle]

		for i in range(extra_shots):
			var angle_mod = angles[i % 2]
			var dist = unit.global_position.distance_to(saved_target_pos)
			var extra_target_pos = unit.global_position + Vector2.RIGHT.rotated(angle_mod) * dist

			var extra_args = {"angle": angle_mod}
			if !target:
				extra_args["target_pos"] = extra_target_pos

			var extra_proj = combat_manager.spawn_projectile(unit, unit.global_position, target, extra_args)
			if extra_proj and is_instance_valid(extra_proj):
				feather_refs.append(extra_proj)

	attack_counter += 1

func on_cleanup():
	for q in feather_refs:
		if is_instance_valid(q):
			q.queue_free()
	feather_refs.clear()

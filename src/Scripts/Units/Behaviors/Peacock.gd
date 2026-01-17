extends "res://src/Scripts/Units/DefaultBehavior.gd"

var feather_refs = []
var attack_counter = 0

func on_combat_tick(delta: float) -> bool:
	if unit.cooldown > 0:
		unit.cooldown -= delta
		return true

	var combat_manager = GameManager.combat_manager
	if !combat_manager: return true

	var target = combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)

	# Peacock Logic
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

	elif target:
		var spawn_logic = func(saved_target_pos: Vector2):
			if !is_instance_valid(combat_manager): return

			var extra_shots = 0
			var multi_chance = 0.0

			if unit.unit_data.has("levels") and unit.unit_data["levels"].has(str(unit.level)):
				var mech = unit.unit_data["levels"][str(unit.level)].get("mechanics", {})
				multi_chance = mech.get("multi_shot_chance", 0.0)

			if multi_chance > 0.0 and randf() < multi_chance:
				extra_shots += 1

			var use_target = null
			var base_angle = 0.0

			if is_instance_valid(target):
				use_target = target
				base_angle = (target.global_position - unit.global_position).angle()
			else:
				base_angle = (saved_target_pos - unit.global_position).angle()

			# Fire Primary Feather
			var proj_args = {}
			if !use_target:
				proj_args["angle"] = base_angle
				proj_args["target_pos"] = saved_target_pos

			var proj = combat_manager.spawn_projectile(unit, unit.global_position, use_target, proj_args)
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
					if !use_target:
						extra_args["target_pos"] = extra_target_pos

					var extra_proj = combat_manager.spawn_projectile(unit, unit.global_position, use_target, extra_args)
					if extra_proj and is_instance_valid(extra_proj):
						feather_refs.append(extra_proj)

			attack_counter += 1

		unit._do_bow_attack(target, spawn_logic)

	return true

func on_cleanup():
	for q in feather_refs:
		if is_instance_valid(q):
			q.queue_free()
	feather_refs.clear()

extends "res://src/Scripts/Enemies/Behaviors/EnemyBehavior.gd"

var path: PackedVector2Array = []
var nav_timer: float = 0.0
var path_index: int = 0
var current_target_tile: Node2D = null
var base_attack_timer: float = 0.0
var anim_tween: Tween

func physics_process(delta: float) -> bool:
	if enemy.state == enemy.State.MOVE:
		_process_move_state(delta)
		return true
	elif enemy.state == enemy.State.ATTACK_BASE:
		_process_attack_state(delta)
		return true
	return false

func _process_move_state(delta):
	nav_timer -= delta
	if nav_timer <= 0:
		update_path()
		nav_timer = 0.5

	var desired_velocity = calculate_move_velocity()

	# Check transition to Attack Base
	if _should_attack_base():
		enemy.state = enemy.State.ATTACK_BASE
		enemy.velocity = Vector2.ZERO
	else:
		enemy.velocity = desired_velocity
		enemy.move_and_slide()

func _process_attack_state(delta):
	if _should_stop_attacking_base():
		enemy.state = enemy.State.MOVE
	else:
		attack_base_logic(delta)
		enemy.velocity = Vector2.ZERO

func _should_attack_base() -> bool:
	var target_pos = GameManager.grid_manager.global_position

	if data.get("attackType") == "ranged":
		var dist = enemy.global_position.distance_to(target_pos)
		var range_val = data.get("range", 200.0)
		if dist < range_val:
			return true
	else:
		if current_target_tile and is_instance_valid(current_target_tile):
			var d = enemy.global_position.distance_to(current_target_tile.global_position)
			var attack_range = data.radius + 10.0
			if d < attack_range:
				return true
	return false

func _should_stop_attacking_base() -> bool:
	var target_pos = GameManager.grid_manager.global_position

	if data.get("attackType") == "ranged":
		var dist = enemy.global_position.distance_to(target_pos)
		var range_val = data.get("range", 200.0)
		return dist > range_val * 1.1
	else:
		if current_target_tile and is_instance_valid(current_target_tile):
			target_pos = current_target_tile.global_position

		var dist = enemy.global_position.distance_to(target_pos)
		var attack_range = data.radius + 10.0

		return dist > attack_range * 1.5

func calculate_move_velocity() -> Vector2:
	var target_pos = GameManager.grid_manager.global_position
	if current_target_tile and is_instance_valid(current_target_tile):
		target_pos = current_target_tile.global_position

	if path.size() > path_index:
		target_pos = path[path_index]

	var dist = enemy.global_position.distance_to(target_pos)
	if dist < 10:
		if path.size() > path_index:
			path_index += 1
			if path_index < path.size():
				target_pos = path[path_index]

	var direction = (target_pos - enemy.global_position).normalized()

	enemy.temp_speed_mod = 1.0
	if enemy.slow_timer > 0: enemy.temp_speed_mod = 0.5

	return direction * enemy.speed * enemy.temp_speed_mod

func update_path():
	if !GameManager.grid_manager: return
	var target_pos = Vector2.ZERO
	current_target_tile = null
	if GameManager.grid_manager.has_method("get_closest_unlocked_tile"):
		current_target_tile = GameManager.grid_manager.get_closest_unlocked_tile(enemy.global_position)
		if current_target_tile:
			target_pos = current_target_tile.global_position
		else:
			target_pos = GameManager.grid_manager.global_position
	else:
		target_pos = GameManager.grid_manager.global_position

	path = GameManager.grid_manager.get_nav_path(enemy.global_position, target_pos)
	if path.size() == 0:
		path = []
	else:
		path_index = 0
		if path.size() > 0 and enemy.global_position.distance_to(path[0]) < 10:
			path_index = 1

func attack_base_logic(delta):
	var target_pos = GameManager.grid_manager.global_position
	if current_target_tile and is_instance_valid(current_target_tile):
		target_pos = current_target_tile.global_position

	base_attack_timer -= delta
	if base_attack_timer <= 0:
		base_attack_timer = 1.0 / data.atkSpeed

		if data.get("attackType") == "ranged":
			play_attack_animation(target_pos, func():
				# Ranged Attack Logic
				if GameManager.combat_manager:
					var proj_type = data.get("proj", "pinecone")
					var core_pos = GameManager.grid_manager.global_position

					GameManager.combat_manager.spawn_projectile(enemy, enemy.global_position, null, {
						"target_pos": core_pos,
						"type": proj_type,
						"damage": data.dmg,
						"speed": data.get("projectileSpeed", 300.0),
						"damageType": "physical"
					})
			)
		else:
			# Melee Attack Logic
			play_attack_animation(target_pos, func():
				GameManager.damage_core(data.dmg)
				if current_target_tile and not is_instance_valid(current_target_tile):
					enemy.state = enemy.State.MOVE
					current_target_tile = null
					update_path()
			)

func play_attack_animation(target_pos: Vector2, hit_callback: Callable = Callable()):
	if anim_tween and anim_tween.is_valid():
		anim_tween.kill()

	anim_tween = enemy.create_tween()
	var original_pos = enemy.global_position
	var diff = target_pos - original_pos
	var direction = diff.normalized()

	var anim_type = "melee"
	if data.get("attackType") == "ranged":
		anim_type = data.get("rangedAnimType", "recoil")

	if anim_type == "melee":
		anim_tween.set_parallel(true)
		anim_tween.tween_property(enemy, "global_position", original_pos - direction * Constants.ANIM_WINDUP_DIST, Constants.ANIM_WINDUP_TIME)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if enemy.visual_controller:
			anim_tween.tween_property(enemy.visual_controller, "wobble_scale", Constants.ANIM_WINDUP_SCALE, Constants.ANIM_WINDUP_TIME)\
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		anim_tween.set_parallel(false)

		anim_tween.set_parallel(true)
		anim_tween.tween_property(enemy, "global_position", original_pos + direction * Constants.ANIM_STRIKE_DIST, Constants.ANIM_STRIKE_TIME)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		if enemy.visual_controller:
			anim_tween.tween_property(enemy.visual_controller, "wobble_scale", Constants.ANIM_STRIKE_SCALE, Constants.ANIM_STRIKE_TIME)\
				.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		anim_tween.set_parallel(false)

		anim_tween.tween_callback(func():
			spawn_slash_effect(target_pos)
			if hit_callback.is_valid():
				hit_callback.call()
		)

		anim_tween.set_parallel(true)
		anim_tween.tween_property(enemy, "global_position", original_pos, Constants.ANIM_RECOVERY_TIME)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if enemy.visual_controller:
			anim_tween.tween_property(enemy.visual_controller, "wobble_scale", Vector2.ONE, Constants.ANIM_RECOVERY_TIME)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		anim_tween.set_parallel(false)

	elif anim_type == "recoil":
		anim_tween.tween_callback(func():
			if hit_callback.is_valid():
				hit_callback.call()
		)
		if enemy.visual_controller:
			anim_tween.tween_property(enemy.visual_controller, "wobble_scale", Vector2(0.8, 0.8), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			anim_tween.tween_property(enemy.visual_controller, "wobble_scale", Vector2.ONE, 0.2)
		anim_tween.parallel().tween_property(enemy, "global_position", original_pos, 0.1)

	elif anim_type == "lunge":
		anim_tween.tween_property(enemy, "global_position", original_pos + direction * 10.0, 0.15)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		anim_tween.tween_callback(func():
			if hit_callback.is_valid():
				hit_callback.call()
		)

		anim_tween.tween_property(enemy, "global_position", original_pos, 0.2)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	elif anim_type == "elastic_shoot":
		if enemy.visual_controller:
			var tween = enemy.visual_controller.play_elastic_shoot()
			tween.tween_callback(func():
				if hit_callback.is_valid():
					hit_callback.call()
			).set_delay(0.4)
		else:
			if hit_callback.is_valid():
				hit_callback.call()

	elif anim_type == "elastic_slash":
		if enemy.visual_controller:
			var tween = enemy.visual_controller.play_elastic_slash()
			tween.tween_callback(func():
				spawn_slash_effect(target_pos)
				if hit_callback.is_valid():
					hit_callback.call()
			).set_delay(0.4)
		else:
			if hit_callback.is_valid():
				hit_callback.call()

func spawn_slash_effect(pos: Vector2):
	var effect = load("res://src/Scripts/Effects/SlashEffect.gd").new()
	enemy.get_parent().add_child(effect)
	effect.global_position = pos
	effect.rotation = randf() * TAU
	var shape = "slash"
	var col = Color.WHITE

	var type_key = enemy.type_key

	if type_key in ["wolf", "boss"]:
		shape = "bite"
		col = Color.RED
	elif type_key in ["slime", "poison"]:
		shape = "bite"
		col = Color.WHITE
	else:
		shape = "cross"
		col = Color.WHITE

	if randf() > 0.5: col = Color(1.0, 0.8, 0.8)
	effect.configure(shape, col)
	effect.play()

extends UnitBehavior
class_name FlyingMeleeBehavior

enum State {
	IDLE,
	WINDUP,
	ATTACK_OUT,
	IMPACT,
	RETURN,
	LANDING
}

var state: State = State.IDLE
var current_target: Node2D = null
var _target_cache_pos: Vector2 = Vector2.ZERO
var _combat_tween: Tween = null
var sprite_faces_left: bool = true

func _init(target_unit: Node2D):
	super._init(target_unit)

func on_combat_tick(delta: float) -> bool:
	# Decrement cooldown if in IDLE
	if state == State.IDLE:
		if unit.cooldown > 0:
			unit.cooldown -= delta
			return true

		# Cooldown ready, look for target
		current_target = _get_target()
		if current_target:
			start_attack_sequence()
		return true

	# Logic during states
	if state == State.WINDUP:
		if is_instance_valid(current_target):
			_target_cache_pos = current_target.global_position

		# Continuously aim at target during windup
		if unit.visual_holder:
			var target_angle = _get_look_angle(_target_cache_pos)
			# Smooth rotation could be nice, but instant lock is more precise for "Aiming"
			unit.visual_holder.rotation = lerp_angle(unit.visual_holder.rotation, target_angle, 10 * delta)

	return true

func _get_look_angle(target_pos: Vector2) -> float:
	var dir = target_pos - unit.global_position
	var angle = dir.angle()
	if sprite_faces_left:
		angle -= PI # Compensate for sprite facing left (PI radians)
	return angle

func start_attack_sequence():
	state = State.WINDUP

	var interval_mod = 1.0
	if GameManager.has_method("get_stat_modifier"):
		interval_mod = GameManager.get_stat_modifier("attack_interval")

	var total_duration = max(0.1, unit.atk_speed * interval_mod)
	unit.cooldown = total_duration

	# Phase Durations
	var t_windup = total_duration * 0.3
	var t_attack = total_duration * 0.1
	var t_impact = total_duration * 0.05
	var t_return = total_duration * 0.35
	var t_landing = total_duration * 0.2

	if is_instance_valid(current_target):
		_target_cache_pos = current_target.global_position

	if _combat_tween: _combat_tween.kill()
	_combat_tween = unit.create_tween()

	# 1. WINDUP - Anticipation
	# Aiming is handled in on_combat_tick
	if unit.visual_holder:
		# Initial aim snap
		unit.visual_holder.rotation = _get_look_angle(_target_cache_pos)

		# Pull back (Local +X is 'Backward' if sprite faces Left and we rotated -PI)
		# Wait, if we rotated -PI, then Local Right (0) points to target?
		# No.
		# Sprite faces Left (-1, 0).
		# We rotate by (Angle - PI).
		# Example: Target Right (0). Rotation = -PI.
		# Sprite's (-1, 0) rotated by -PI becomes (1, 0) -> Points Right. Correct.
		# So Local (-1, 0) is "Forward". Local (1, 0) is "Backward".

		# Anticipation: Move "Backward" (Local +X)
		var backward_dir = Vector2(1, 0).rotated(0) # In local space

		# Scale: Compress (Squash X, Stretch Y)
		_combat_tween.tween_property(unit.visual_holder, "scale", Vector2(0.8, 1.2), t_windup)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

		# We can't easily tween "local position offset" relative to rotation if we are setting global position later.
		# But we are currently at (0,0) local.
		# Let's just tween scale for now to avoid fighting with rotation logic if we move visual holder?
		# Actually, moving visual_holder locally works fine even if rotated.
		# Move back 20px
		_combat_tween.parallel().tween_property(unit.visual_holder, "position", Vector2(20, 0), t_windup)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	else:
		_combat_tween.tween_interval(t_windup)

	_combat_tween.tween_callback(func(): _enter_attack_out(t_attack, t_impact, t_return, t_landing))

func _enter_attack_out(t_attack, t_impact, t_return, t_landing):
	state = State.ATTACK_OUT

	var target_pos = _target_cache_pos

	if unit.visual_holder:
		if _combat_tween: _combat_tween.kill()
		_combat_tween = unit.create_tween()

		# Lock rotation to final target pos
		unit.visual_holder.rotation = _get_look_angle(target_pos)

		# Stretch (Elongate X, Squash Y) - "Dash" shape
		_combat_tween.tween_property(unit.visual_holder, "scale", Vector2(1.6, 0.6), t_attack)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

		# Move to Global Target
		_combat_tween.parallel().tween_property(unit.visual_holder, "global_position", target_pos, t_attack)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

		_combat_tween.tween_callback(func(): _enter_impact(t_impact, t_return, t_landing))
	else:
		if _combat_tween: _combat_tween.kill()
		_combat_tween = unit.create_tween()
		_combat_tween.tween_interval(t_attack)
		_combat_tween.tween_callback(func(): _enter_impact(t_impact, t_return, t_landing))

func _enter_impact(t_impact, t_return, t_landing):
	state = State.IMPACT

	if is_instance_valid(current_target):
		var dmg = _calculate_damage(current_target)
		current_target.take_damage(dmg, unit, "physical")

		if GameManager.has_method("trigger_impact"):
			var dir = (current_target.global_position - unit.global_position).normalized()
			GameManager.trigger_impact(dir, 0.5)

		GameManager.spawn_floating_text(_target_cache_pos, "HIT!", Color.WHITE)

	if unit.visual_holder:
		if _combat_tween: _combat_tween.kill()
		_combat_tween = unit.create_tween()

		# Squash on impact (Squash X, Expand Y) - "Wall hit"
		_combat_tween.tween_property(unit.visual_holder, "scale", Vector2(0.5, 1.5), t_impact * 0.5)\
			.set_trans(Tween.TRANS_BOUNCE)
		_combat_tween.tween_property(unit.visual_holder, "scale", Vector2(1.0, 1.0), t_impact * 0.5)

		_combat_tween.tween_callback(func(): _enter_return(t_return, t_landing))
	else:
		if _combat_tween: _combat_tween.kill()
		_combat_tween = unit.create_tween()
		_combat_tween.tween_interval(t_impact)
		_combat_tween.tween_callback(func(): _enter_return(t_return, t_landing))

func _enter_return(t_return, t_landing):
	state = State.RETURN

	if unit.visual_holder:
		if _combat_tween: _combat_tween.kill()
		_combat_tween = unit.create_tween()

		# Turn around to face home?
		# Home is unit.global_position (parent position). Visual holder is at offset.
		# Vector to home from current visual pos:
		var current_vis_pos = unit.visual_holder.global_position
		var home_pos = unit.global_position
		var dir_to_home = home_pos - current_vis_pos
		var return_angle = dir_to_home.angle()
		if sprite_faces_left: return_angle -= PI

		unit.visual_holder.rotation = return_angle

		# Return Stretch
		unit.visual_holder.scale = Vector2(1.2, 0.9)

		# Move back to local zero
		_combat_tween.tween_property(unit.visual_holder, "position", Vector2.ZERO, t_return)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_combat_tween.parallel().tween_property(unit.visual_holder, "scale", Vector2.ONE, t_return)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		_combat_tween.tween_callback(func(): _enter_landing(t_landing))
	else:
		if _combat_tween: _combat_tween.kill()
		_combat_tween = unit.create_tween()
		_combat_tween.tween_interval(t_return)
		_combat_tween.tween_callback(func(): _enter_landing(t_landing))

func _enter_landing(t_landing):
	state = State.LANDING

	if unit.visual_holder:
		if _combat_tween: _combat_tween.kill()
		_combat_tween = unit.create_tween()

		# Reset rotation to default (0) smoothly or instantly?
		# Instantly might snap. Smoothly is better.
		_combat_tween.tween_property(unit.visual_holder, "rotation", 0.0, t_landing * 0.3)

		# Landing Wobble
		_combat_tween.parallel().tween_property(unit.visual_holder, "scale", Vector2(1.1, 0.9), t_landing * 0.3)
		_combat_tween.tween_property(unit.visual_holder, "scale", Vector2(0.95, 1.05), t_landing * 0.3)
		_combat_tween.tween_property(unit.visual_holder, "scale", Vector2.ONE, t_landing * 0.4)

		_combat_tween.tween_callback(func():
			state = State.IDLE
			current_target = null
			unit.visual_holder.rotation = 0 # Ensure clean reset
		)
	else:
		if _combat_tween: _combat_tween.kill()
		_combat_tween = unit.create_tween()
		_combat_tween.tween_interval(t_landing)
		_combat_tween.tween_callback(func():
			state = State.IDLE
			current_target = null
		)

func on_cleanup():
	if _combat_tween:
		_combat_tween.kill()

# Virtual Methods to be overridden by subclasses
func _get_target() -> Node2D:
	return null

func _calculate_damage(target: Node2D) -> float:
	return unit.damage

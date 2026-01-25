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

var _state = State.IDLE
var _target_cache_pos: Vector2 = Vector2.ZERO
var _current_target: Node2D = null
var _behavior_tween: Tween = null
var _original_local_pos: Vector2 = Vector2.ZERO

# Animation Ratios
const RATIO_WINDUP = 0.30
const RATIO_ATTACK = 0.10
const RATIO_IMPACT = 0.05
const RATIO_RETURN = 0.35
const RATIO_LANDING = 0.20

func on_setup():
	super.on_setup()
	if unit and unit.visual_holder:
		_original_local_pos = unit.visual_holder.position

func on_combat_tick(delta: float) -> bool:
	# If we are in a sequence, we return true to block default combat
	if _state != State.IDLE:
		# During WINDUP, track target
		if _state == State.WINDUP:
			if is_instance_valid(_current_target):
				_target_cache_pos = _current_target.global_position
		return true

	# State is IDLE
	if unit.cooldown > 0:
		unit.cooldown -= delta
		return true # We handle cooldown blocking

	# Ready to attack
	var target = _find_target()
	if target:
		_start_sequence(target)
		return true

	return true

func _find_target() -> Node2D:
	# Default implementation: Nearest enemy
	if unit.combat_manager:
		return unit.combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)
	return null

func _start_sequence(target: Node2D):
	_current_target = target
	_target_cache_pos = target.global_position # Initial lock

	# Calculate dynamic duration
	var base_interval = GameManager.get_stat_modifier("attack_interval")
	var total_duration = unit.atk_speed * base_interval

	# Ensure a minimum duration so animations are visible
	total_duration = max(0.5, total_duration)

	_enter_windup(total_duration)

func _enter_windup(total_duration: float):
	_state = State.WINDUP
	var duration = total_duration * RATIO_WINDUP

	if _behavior_tween: _behavior_tween.kill()
	_behavior_tween = unit.create_tween()

	# Windup animation: Pull back / squash
	if unit.visual_holder:
		_behavior_tween.tween_property(unit.visual_holder, "scale", Vector2(0.8, 1.2), duration).set_trans(Tween.TRANS_SINE)

	_behavior_tween.tween_callback(func(): _enter_attack_out(total_duration))

func _enter_attack_out(total_duration: float):
	_state = State.ATTACK_OUT
	var duration = total_duration * RATIO_ATTACK

	# Update target one last time if valid
	if is_instance_valid(_current_target):
		_target_cache_pos = _current_target.global_position

	if _behavior_tween: _behavior_tween.kill()
	_behavior_tween = unit.create_tween()

	# Tween to target
	if unit.visual_holder:
		# Convert global target pos to local pos relative to unit
		var target_local = unit.to_local(_target_cache_pos)

		# Move to target
		_behavior_tween.tween_property(unit.visual_holder, "position", target_local, duration)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

		# Stretch for speed effect (parallel)
		_behavior_tween.parallel().tween_property(unit.visual_holder, "scale", Vector2(1.5, 0.5), duration)

	_behavior_tween.tween_callback(func(): _enter_impact(total_duration))

func _enter_impact(total_duration: float):
	_state = State.IMPACT
	var duration = total_duration * RATIO_IMPACT

	# Logic: Damage and FX
	if is_instance_valid(_current_target):
		_apply_damage_logic(_current_target)
	else:
		# Target dead, still play FX at _target_cache_pos logic
		pass

	# Screen Shake (placeholder if GameManager has it, or we can emit signal)
	if GameManager.has_method("shake_camera"):
		GameManager.shake_camera(3.0)

	if _behavior_tween: _behavior_tween.kill()
	_behavior_tween = unit.create_tween()

	# Impact squash
	if unit.visual_holder:
		_behavior_tween.tween_property(unit.visual_holder, "scale", Vector2(1.5, 0.5), duration * 0.5)
		_behavior_tween.tween_property(unit.visual_holder, "scale", Vector2(1.0, 1.0), duration * 0.5)

	_behavior_tween.tween_callback(func(): _enter_return(total_duration))

func _enter_return(total_duration: float):
	_state = State.RETURN
	var duration = total_duration * RATIO_RETURN

	if _behavior_tween: _behavior_tween.kill()
	_behavior_tween = unit.create_tween()

	# Return to original local pos
	if unit.visual_holder:
		_behavior_tween.tween_property(unit.visual_holder, "position", _original_local_pos, duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		# Reset scale
		_behavior_tween.parallel().tween_property(unit.visual_holder, "scale", Vector2.ONE, duration)

	_behavior_tween.tween_callback(func(): _enter_landing(total_duration))

func _enter_landing(total_duration: float):
	_state = State.LANDING
	var duration = total_duration * RATIO_LANDING

	if _behavior_tween: _behavior_tween.kill()
	_behavior_tween = unit.create_tween()

	# Landing bounce
	if unit.visual_holder:
		_behavior_tween.tween_property(unit.visual_holder, "scale", Vector2(1.1, 0.9), duration * 0.5)
		_behavior_tween.tween_property(unit.visual_holder, "scale", Vector2.ONE, duration * 0.5)

	_behavior_tween.tween_callback(_end_sequence)

func _end_sequence():
	_state = State.IDLE
	# Set cooldown
	unit.cooldown = unit.atk_speed * GameManager.get_stat_modifier("attack_interval")

func _apply_damage_logic(target: Node2D):
	if !is_instance_valid(target): return
	var dmg = unit.calculate_damage_against(target)
	target.take_damage(dmg, unit)

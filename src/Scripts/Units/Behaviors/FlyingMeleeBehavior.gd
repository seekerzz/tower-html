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
		# If target dies/invalid, we keep the last _target_cache_pos

	return true

func start_attack_sequence():
	state = State.WINDUP

	# Calculate total duration based on attack interval
	var interval_mod = 1.0
	if GameManager.has_method("get_stat_modifier"):
		interval_mod = GameManager.get_stat_modifier("attack_interval")

	var total_duration = max(0.1, unit.atk_speed * interval_mod)
	unit.cooldown = total_duration # Reset cooldown

	# Calculate phase durations based on spec
	# Windup (30%) -> Attack (10%) -> Impact (5%) -> Return (35%) -> Landing (20%)
	var t_windup = total_duration * 0.3
	var t_attack = total_duration * 0.1
	var t_impact = total_duration * 0.05
	var t_return = total_duration * 0.35
	var t_landing = total_duration * 0.2

	if is_instance_valid(current_target):
		_target_cache_pos = current_target.global_position

	# Kill existing tween
	if _combat_tween: _combat_tween.kill()
	_combat_tween = unit.create_tween()

	# 1. WINDUP
	# Visual tell: Scale up slightly to indicate gathering energy
	if unit.visual_holder:
		_combat_tween.tween_property(unit.visual_holder, "scale", Vector2(1.2, 1.2), t_windup)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_combat_tween.tween_interval(t_windup)

	_combat_tween.tween_callback(func(): _enter_attack_out(t_attack, t_impact, t_return, t_landing))

func _enter_attack_out(t_attack, t_impact, t_return, t_landing):
	state = State.ATTACK_OUT

	# Target position is locked to _target_cache_pos (updated during WINDUP)
	var target_pos = _target_cache_pos

	if unit.visual_holder:
		# Create new tween for this phase to ensure clean state
		if _combat_tween: _combat_tween.kill()
		_combat_tween = unit.create_tween()

		# Use global_position for precise targeting to the enemy's world location
		# TRANS_EXPO + EASE_IN for "sudden dash" feel
		_combat_tween.tween_property(unit.visual_holder, "global_position", target_pos, t_attack)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

		_combat_tween.tween_callback(func(): _enter_impact(t_impact, t_return, t_landing))
	else:
		# Fallback if no visuals
		if _combat_tween: _combat_tween.kill()
		_combat_tween = unit.create_tween()
		_combat_tween.tween_interval(t_attack)
		_combat_tween.tween_callback(func(): _enter_impact(t_impact, t_return, t_landing))

func _enter_impact(t_impact, t_return, t_landing):
	state = State.IMPACT

	# Apply Damage / Effects
	if is_instance_valid(current_target):
		var dmg = _calculate_damage(current_target)
		# Assuming take_damage takes (amount, source_unit, type)
		current_target.take_damage(dmg, unit, "physical")

		if GameManager.has_method("trigger_impact"):
			var dir = (current_target.global_position - unit.global_position).normalized()
			GameManager.trigger_impact(dir, 0.5)

		# Visual Hit Effect (Shake or Particles could be added here)
		GameManager.spawn_floating_text(_target_cache_pos, "HIT!", Color.WHITE)
	else:
		# Target missing, but we still play impact at location
		pass

	# Impact Animation (Squash)
	if unit.visual_holder:
		if _combat_tween: _combat_tween.kill()
		_combat_tween = unit.create_tween()

		# Squash effect
		_combat_tween.tween_property(unit.visual_holder, "scale", Vector2(1.5, 0.5), t_impact * 0.5)\
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

		# Return to local ZERO (relative to unit parent)
		_combat_tween.tween_property(unit.visual_holder, "position", Vector2.ZERO, t_return)\
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

		# Small recovery bounce
		_combat_tween.tween_property(unit.visual_holder, "scale", Vector2(1.1, 0.9), t_landing * 0.5)
		_combat_tween.tween_property(unit.visual_holder, "scale", Vector2.ONE, t_landing * 0.5)

		_combat_tween.tween_callback(func():
			state = State.IDLE
			current_target = null
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

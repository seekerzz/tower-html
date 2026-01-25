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

var tween: Tween = null
var state_timer: float = 0.0

# Percentages for each phase
const PHASE_WINDUP = 0.30
const PHASE_ATTACK = 0.10
const PHASE_IMPACT = 0.05
const PHASE_RETURN = 0.35
const PHASE_LANDING = 0.20

func on_combat_tick(delta: float) -> bool:
	# Handle cooldown in IDLE
	if state == State.IDLE:
		if unit.cooldown > 0:
			unit.cooldown -= delta
			return true

		# Try to find target
		var target = _get_target()
		if target:
			# Check mana
			if unit.attack_cost_mana > 0:
				if !GameManager.check_resource("mana", unit.attack_cost_mana):
					unit.is_no_mana = true
					return true # Take over but do nothing (wait for mana)
				GameManager.consume_resource("mana", unit.attack_cost_mana)
				unit.is_no_mana = false

			_start_attack_sequence(target)

	return true

func _start_attack_sequence(target: Node2D):
	current_target = target
	state = State.WINDUP

	# Calculate total duration based on attack speed (1.0 / atk_speed usually implies attacks per second, but Unit.gd treats atk_speed as interval base?)
	# Unit.gd: cooldown = atk_speed * GameManager.get_stat_modifier("attack_interval")
	# So atk_speed is the base interval.
	var total_duration = unit.atk_speed * GameManager.get_stat_modifier("attack_interval")
	# Clamp to be safe/responsive? The prompt says "Dynamic Duration / Speed Up".
	# If we strictly follow percentages of the interval, it scales perfectly.

	_enter_windup(total_duration)

func _enter_windup(total_duration: float):
	state = State.WINDUP

	var duration = total_duration * PHASE_WINDUP

	# Initial target position
	if is_instance_valid(current_target):
		_target_cache_pos = current_target.global_position

	# Use a tween to handle the timing and continuous update if needed,
	# but for continuous update of _target_cache_pos, we might need process.
	# However, we can just tween a dummy value or use a timer.
	# To ensure strictly following the target, let's use a tween on a dummy property or just a timer and update manually.
	# Actually, we can update _target_cache_pos in on_tick or right before transition.

	if tween: tween.kill()
	tween = unit.create_tween()

	# WINDUP Animation: Pull back slightly (opposite to target)
	var dir = (_target_cache_pos - unit.global_position).normalized()
	# Visual holder moves locally.
	var pullback_pos = -dir * 20.0 # Small pullback

	tween.tween_property(unit.visual_holder, "position", pullback_pos, duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# We use a method callback to update target pos during windup?
	# Or just update it at the END of windup.
	# The prompt says: "In Tween's every frame or end, continuously update _target_cache_pos".
	# Updating at end is easiest and usually sufficient.

	tween.tween_callback(func():
		if is_instance_valid(current_target):
			_target_cache_pos = current_target.global_position
		_enter_attack_out(total_duration)
	)

func _enter_attack_out(total_duration: float):
	state = State.ATTACK_OUT
	var duration = total_duration * PHASE_ATTACK

	if tween: tween.kill()
	tween = unit.create_tween()

	# Move Visual Holder to Global Target Position.
	# Since visual_holder is a child of Unit (which is at unit.global_position),
	# we need to set its GLOBAL position.
	# Godot Tween property handles local properties by default.
	# We can tween "global_position".

	tween.tween_property(unit.visual_holder, "global_position", _target_cache_pos, duration)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	tween.tween_callback(func(): _enter_impact(total_duration))

func _enter_impact(total_duration: float):
	state = State.IMPACT
	var duration = total_duration * PHASE_IMPACT

	# Damage Logic
	if is_instance_valid(current_target):
		var dmg = _calculate_damage(current_target)
		current_target.take_damage(dmg, unit, "melee")

		# Visual Impact Effects
		GameManager.trigger_impact((current_target.global_position - unit.global_position).normalized(), 1.0)
		# Spawn particles? (Optional)
	else:
		# Target dead/gone, just play effect at cache pos
		GameManager.trigger_impact((_target_cache_pos - unit.global_position).normalized(), 0.5)

	# Squish animation or shake
	if tween: tween.kill()
	tween = unit.create_tween()
	tween.tween_property(unit.visual_holder, "scale", Vector2(1.2, 0.8), duration * 0.5)
	tween.tween_property(unit.visual_holder, "scale", Vector2(1.0, 1.0), duration * 0.5)

	tween.tween_callback(func(): _enter_return(total_duration))

func _enter_return(total_duration: float):
	state = State.RETURN
	var duration = total_duration * PHASE_RETURN

	if tween: tween.kill()
	tween = unit.create_tween()

	# Return to local zero (relative to Unit parent)
	tween.tween_property(unit.visual_holder, "position", Vector2.ZERO, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_callback(func(): _enter_landing(total_duration))

func _enter_landing(total_duration: float):
	state = State.LANDING
	var duration = total_duration * PHASE_LANDING

	# Small recovery bob
	if tween: tween.kill()
	tween = unit.create_tween()
	tween.tween_property(unit.visual_holder, "scale", Vector2(1.05, 0.95), duration * 0.5)
	tween.tween_property(unit.visual_holder, "scale", Vector2.ONE, duration * 0.5)

	tween.tween_callback(func():
		state = State.IDLE
		# Cooldown is effectively handled by the duration of the animation,
		# but if we want extra cooldown we set it here.
		# Usually cooldown resets after attack starts.
		# Unit.gd sets cooldown = interval at start.
		# Since we consumed the whole interval in the animation, cooldown should be 0 now?
		# Or rather, the animation IS the cooldown.
		# Unit.gd: cooldown = atk_speed...
		# If we want the unit to attack immediately after landing, we set cooldown to 0.
		unit.cooldown = 0.0
	)

# Virtual Methods
func _get_target() -> Node2D:
	if GameManager.combat_manager:
		return GameManager.combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)
	return null

func _calculate_damage(target: Node2D) -> float:
	return unit.calculate_damage_against(target)

func on_cleanup():
	if tween:
		tween.kill()

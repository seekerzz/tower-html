extends UnitBehavior

var current_target_ref: WeakRef = null
var stack_count: int = 0
var stack_bonus: float = 0.1

func _init(target_unit: Node2D):
	super._init(target_unit)
	if unit.unit_data.has("mechanics") and unit.unit_data.mechanics.has("stack_bonus"):
		stack_bonus = unit.unit_data.mechanics.stack_bonus

func on_stats_updated():
	if unit.unit_data.has("mechanics") and unit.unit_data.mechanics.has("stack_bonus"):
		stack_bonus = unit.unit_data.mechanics.stack_bonus

func on_combat_tick(delta: float) -> bool:
	if unit.cooldown > 0:
		unit.cooldown -= delta
		return true

	# Find nearest enemy
	if not GameManager.combat_manager:
		return true

	var target = GameManager.combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)

	if target == null:
		if current_target_ref != null:
			# Lost target, reset stack
			stack_count = 0
			current_target_ref = null
		return true

	# Check target continuity
	var is_same_target = false
	if current_target_ref != null:
		var prev_target = current_target_ref.get_ref()
		if prev_target == target:
			is_same_target = true

	if is_same_target:
		stack_count += 1
	else:
		stack_count = 0
		current_target_ref = weakref(target)

	# Calculate damage
	var base_damage = unit.damage
	var final_damage = base_damage * (1.0 + float(stack_count) * stack_bonus)

	var extra_stats = {
		"damage": final_damage
	}

	# Spawn Projectile
	GameManager.combat_manager.spawn_projectile(unit, unit.global_position, target, extra_stats)

	# Reset Cooldown
	unit.cooldown = unit.atk_speed

	# Animation
	if unit.has_method("play_attack_anim"):
		unit.play_attack_anim("ranged", target.global_position)

	return true

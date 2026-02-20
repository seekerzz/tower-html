extends "res://src/Scripts/Units/UnitBehavior.gd"

# Woodpecker - 啄木鸟
# 对同一目标连续攻击伤害增加
# Lv1: 攻击同一目标时每次伤害+10%(上限+100%)
# Lv2: 叠加速度+50%(每次+15%), 上限150%
# Lv3: 叠满后下3次攻击必定暴击并触发图腾回响

var drill_target: WeakRef = null
var drill_stacks: int = 0
var max_drill_stacks: int = 10

func _init(target_unit: Node2D):
	super._init(target_unit)

func on_combat_tick(delta: float) -> bool:
	if unit.cooldown > 0:
		unit.cooldown -= delta
		return true

	if not GameManager.combat_manager: return true

	var target = null
	# Check if current target is still valid and in range
	if drill_target and drill_target.get_ref() and is_instance_valid(drill_target.get_ref()) and drill_target.get_ref().hp > 0:
		if drill_target.get_ref().global_position.distance_to(unit.global_position) <= unit.range_val:
			target = drill_target.get_ref()

	if not target:
		target = GameManager.combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)

	if target:
		var prev_target = drill_target.get_ref() if drill_target else null

		if target != prev_target:
			drill_stacks = 0
			drill_target = weakref(target)

		_perform_attack(target)

		# Increment stack AFTER attack (only if target didn't change this frame)
		if target == prev_target:
			var old_stacks = drill_stacks
			drill_stacks = min(drill_stacks + 1, max_drill_stacks)

			if unit.level >= 3 and old_stacks < max_drill_stacks and drill_stacks == max_drill_stacks:
				_enter_drill_master_mode()
	else:
		if drill_stacks > 0:
			drill_stacks = 0
			drill_target = null

	return true

func _perform_attack(target):
	var per_stack = 0.10
	if unit.level >= 2:
		per_stack = 0.15

	var bonus = 1.0 + (drill_stacks * per_stack)
	var final_damage = unit.damage * bonus

	var stats = { "damage": final_damage }

	# Lv3: Guaranteed Crit triggers Echo (Check before CombatManager consumes stack)
	if unit.guaranteed_crit_stacks > 0 and unit.level >= 3:
		stats["force_echo"] = true

	GameManager.combat_manager.spawn_projectile(unit, unit.global_position, target, stats)

	unit.cooldown = unit.atk_speed
	if unit.has_method("play_attack_anim"):
		unit.play_attack_anim("ranged", target.global_position)

func _enter_drill_master_mode():
	if unit.guaranteed_crit_stacks <= 0:
		unit.add_crit_stacks(3)
		GameManager.spawn_floating_text(unit.global_position, "DRILL MODE!", Color.ORANGE)

extends "res://src/Scripts/Units/Behaviors/FlyingMeleeBehavior.gd"

# Vulture - 秃鹫
# 优先攻击生命值最低敌人
# Lv2: 对生命值<30%敌人伤害+30%
# 击杀敌人获得永久攻击力加成（上限15）
# Lv3: 击杀时触发图腾回响

var kill_count: int = 0
var permanent_attack_bonus: int = 0

func _init(target_unit: Node2D):
	super._init(target_unit)

func _get_target() -> Node2D:
	# Lowest HP
	var enemies = unit.get_tree().get_nodes_in_group("enemies")
	var best_target = null
	var min_hp = 9999999.0

	for enemy in enemies:
		if !is_instance_valid(enemy): continue
		var dist = unit.global_position.distance_to(enemy.global_position)
		if dist <= unit.range_val:
			if enemy.hp < min_hp:
				min_hp = enemy.hp
				best_target = enemy
	return best_target

func _calculate_damage(target: Node2D) -> float:
	# Apply permanent bonus manually as it's not in unit stats until updated
	# Or assume on_stats_updated handles unit.damage
	# If on_stats_updated handles it, then unit.damage includes bonus.

	var dmg = unit.damage

	var hp_percent = 1.0
	if target.max_hp > 0:
		hp_percent = target.hp / target.max_hp

	if unit.level >= 2 and hp_percent < 0.3:
		dmg *= 1.3

	return dmg

func on_stats_updated():
	unit.damage += permanent_attack_bonus

func _enter_claw_impact(t_impact, t_return, t_landing):
	# Override to check kill
	state = State.IMPACT
	if is_instance_valid(current_target):
		var dmg = _calculate_damage(current_target)

		# Check probable kill
		var will_die = current_target.hp <= dmg

		current_target.take_damage(dmg, unit, "physical")

		if GameManager.has_method("trigger_impact"):
			GameManager.trigger_impact((current_target.global_position - unit.global_position).normalized(), 0.3)

		if will_die or (is_instance_valid(current_target) and current_target.hp <= 0):
			_on_kill(current_target, dmg)

	# Animation
	if unit.visual_holder:
		if _combat_tween: _combat_tween.kill()
		_combat_tween = unit.create_tween()
		var target_scale = Vector2(0.5, 1.5 * _current_y_scale_sign)
		var recovery_scale = Vector2(1.0, 1.0 * _current_y_scale_sign)
		_combat_tween.tween_property(unit.visual_holder, "scale", target_scale, t_impact * 0.5)\
			.set_trans(Tween.TRANS_BOUNCE)
		_combat_tween.tween_property(unit.visual_holder, "scale", recovery_scale, t_impact * 0.5)
		_combat_tween.tween_callback(func(): _enter_return(t_return, t_landing))
	else:
		if _combat_tween: _combat_tween.kill()
		_combat_tween = unit.create_tween()
		_combat_tween.tween_interval(t_impact)
		_combat_tween.tween_callback(func(): _enter_return(t_return, t_landing))

func _on_kill(enemy, damage):
	if permanent_attack_bonus < 15:
		permanent_attack_bonus += 1
		kill_count += 1
		unit.damage += 1 # Update current stat immediately
		GameManager.spawn_floating_text(unit.global_position, "+1 ATK", Color.RED)

	if unit.level >= 3:
		GameManager.projectile_crit.emit(unit, enemy, damage)

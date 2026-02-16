extends FlyingMeleeBehavior

# Vulture - 腐食增益
# 周围有敌人死亡时，自身攻击+X%持续5秒

var damage_bonus_percent: float = 0.05
var lifesteal_percent: float = 0.0
var buff_duration: float = 5.0
var detection_range: float = 300.0

var _current_buff_stacks: int = 0
var _buff_timer: float = 0.0
var _original_damage: float = 0.0

func _init(target_unit: Node2D):
	super._init(target_unit)

func on_setup():
	_update_mechanics()
	_connect_to_enemy_deaths()

func _update_mechanics():
	var lvl_stats = unit.unit_data.get("levels", {}).get(str(unit.level), {})
	var mechanics = lvl_stats.get("mechanics", {})

	# 根据等级设置攻击加成和吸血
	damage_bonus_percent = mechanics.get("damage_bonus_percent", 0.05)
	lifesteal_percent = mechanics.get("lifesteal_percent", 0.0)
	detection_range = mechanics.get("detection_range", 300.0)

func on_stats_updated():
	_update_mechanics()

func _connect_to_enemy_deaths():
	# 连接到场上的敌人死亡信号
	if not unit.is_inside_tree():
		return
	var tree = unit.get_tree()
	if not tree:
		return
	var enemies = tree.get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_signal("died"):
			if not enemy.died.is_connected(_on_enemy_died):
				enemy.died.connect(_on_enemy_died)

func _on_enemy_died():
	# 检查是否有敌人在检测范围内死亡
	# 由于无法直接知道死亡敌人的位置，我们检查当前所有敌人
	# 实际上，我们应该定期检查范围内的敌人数量变化
	pass

func on_tick(delta: float):
	# 更新BUFF持续时间
	if _buff_timer > 0:
		_buff_timer -= delta
		if _buff_timer <= 0:
			_remove_buff()

	# 检查范围内是否有敌人死亡（通过监听新敌人的生成和检测）
	_check_for_carrion()

func _check_for_carrion():
	# 获取当前所有敌人
	var enemies = unit.get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if not is_instance_valid(enemy): continue

		# 检查敌人是否在范围内且生命值很低（濒死）
		var dist = unit.global_position.distance_to(enemy.global_position)
		if dist <= detection_range:
			# 连接死亡信号（如果还没连接）
			if enemy.has_signal("died"):
				if not enemy.died.is_connected(_on_nearby_enemy_died):
					enemy.died.connect(_on_nearby_enemy_died.bind(enemy))

func _on_nearby_enemy_died(enemy: Node2D):
	# 附近有敌人死亡，触发增益
	_apply_buff()

func _apply_buff():
	# 保存原始伤害
	if _original_damage == 0:
		_original_damage = unit.damage

	# 增加BUFF层数（最多叠加到5层）
	_current_buff_stacks = min(_current_buff_stacks + 1, 5)

	# 计算总加成
	var total_bonus = damage_bonus_percent * _current_buff_stacks
	unit.damage = _original_damage * (1.0 + total_bonus)

	# 重置计时器
	_buff_timer = buff_duration

	# 显示增益效果
	var bonus_text = "+%d%% ATK" % int(total_bonus * 100)
	GameManager.spawn_floating_text(unit.global_position, bonus_text, Color.ORANGE)

func _remove_buff():
	if _original_damage > 0:
		unit.damage = _original_damage
	_current_buff_stacks = 0
	GameManager.spawn_floating_text(unit.global_position, "BUFF END", Color.GRAY)

func _calculate_damage(target: Node2D) -> float:
	var dmg = unit.damage

	# 如果有吸血效果
	if lifesteal_percent > 0 and is_instance_valid(unit):
		var heal_amount = dmg * lifesteal_percent
		# 这里假设单位有 heal 方法或者通过其他方式恢复生命
		# 暂时通过 GameManager 显示治疗效果
		if heal_amount > 1:
			GameManager.spawn_floating_text(unit.global_position, "+%d HP" % int(heal_amount), Color.GREEN)

	return dmg

func _get_target() -> Node2D:
	# 寻找最近的敌人
	var enemies = unit.get_tree().get_nodes_in_group("enemies")
	var nearest = null
	var min_dist = unit.range_val

	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		var dist = unit.global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = enemy

	return nearest

func on_cleanup():
	# 断开所有信号连接
	var enemies = unit.get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_signal("died"):
			if enemy.died.is_connected(_on_nearby_enemy_died):
				enemy.died.disconnect(_on_nearby_enemy_died)

extends DefaultBehavior

# Medusa - 美杜莎
# 机制: 石化凝视 - 周期石化最近敌人，被石化敌人可触发陷阱连锁
# L1: 石化3秒
# L2: 石化5秒，结束造成范围伤害
# L3: 石化8秒，结束造成高额伤害

var _petrify_timer: float = 0.0
var _petrify_interval: float = 3.0  # 每3秒触发一次石化

# 追踪被石化的敌人
var _petrified_enemies: Dictionary = {}  # enemy_instance_id -> {end_time, position, level}

func on_setup():
	_petrify_timer = _petrify_interval

func on_cleanup():
	# 清理所有石化效果
	for enemy_id in _petrified_enemies:
		var enemy = instance_from_id(enemy_id)
		if is_instance_valid(enemy) and enemy.has_method("apply_stun"):
			# 提前结束石化
			pass
	_petrified_enemies.clear()

func on_combat_tick(delta: float) -> bool:
	if not GameManager.combat_manager:
		return true

	# 更新石化计时器
	_petrify_timer -= delta
	if _petrify_timer <= 0:
		_petrify_timer = _petrify_interval
		_petrify_nearest_enemy()

	# 检查并处理石化结束的敌人
	_check_petrified_enemies()

	return true

func _petrify_nearest_enemy():
	# 获取当前等级的机制数据
	var mechanics = _get_mechanics()
	if mechanics.is_empty():
		return

	# 寻找最近的敌人
	var target = GameManager.combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)
	if not target:
		return

	# 获取石化持续时间
	var petrify_duration = mechanics.get("petrify_duration", 3.0)
	var level = unit.level

	# 应用石化（使用晕眩作为石化效果）
	if target.has_method("apply_stun"):
		target.apply_stun(petrify_duration)

	# 记录被石化的敌人
	var enemy_id = target.get_instance_id()
	_petrified_enemies[enemy_id] = {
		"end_time": Time.get_time_dict_from_system()["second"] + petrify_duration,
		"position": target.global_position,
		"level": level,
		"processed": false
	}

	# 显示石化效果
	GameManager.spawn_floating_text(target.global_position, "Petrified!", Color.GRAY)

	# 创建石化视觉效果
	_spawn_petrify_effect(target.global_position)

func _check_petrified_enemies():
	var current_time = Time.get_time_dict_from_system()["second"]
	var to_remove = []

	for enemy_id in _petrified_enemies:
		var data = _petrified_enemies[enemy_id]
		if data["processed"]:
			continue

		# 检查敌人是否仍然有效
		var enemy = instance_from_id(enemy_id)
		if not is_instance_valid(enemy):
			# 敌人在石化期间死亡，触发结束效果
			_trigger_petrify_end_effect(data)
			to_remove.append(enemy_id)
			continue

		# 检查石化是否结束
		if current_time >= data["end_time"]:
			_trigger_petrify_end_effect(data)
			data["processed"] = true
			to_remove.append(enemy_id)

	for enemy_id in to_remove:
		_petrified_enemies.erase(enemy_id)

func _trigger_petrify_end_effect(data: Dictionary):
	var level = data["level"]
	var position = data["position"]

	# L2+: 石化结束造成范围伤害
	if level >= 2:
		var damage = 0.0
		if level == 2:
			damage = 200.0  # L2范围伤害
		elif level == 3:
			damage = 500.0  # L3高额伤害

		if damage > 0:
			_deal_aoe_damage(position, damage)

func _deal_aoe_damage(center_pos: Vector2, damage: float):
	var range_sq = (Constants.TILE_SIZE * 2.0) ** 2  # 2格范围

	var enemies = unit.get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.global_position.distance_squared_to(center_pos) <= range_sq:
			enemy.take_damage(damage, unit, "magic", unit)

	# 显示范围效果
	_spawn_aoe_effect(center_pos)

func _spawn_petrify_effect(pos: Vector2):
	# 创建石化视觉效果
	var effect = load("res://src/Scripts/Effects/SlashEffect.gd").new()
	if effect:
		unit.get_tree().current_scene.add_child(effect)
		effect.global_position = pos
		effect.configure("cross", Color.GRAY)
		effect.scale = Vector2(1.5, 1.5)
		effect.play()

func _spawn_aoe_effect(pos: Vector2):
	# 创建范围爆炸效果
	var effect = load("res://src/Scripts/Effects/SlashEffect.gd").new()
	if effect:
		unit.get_tree().current_scene.add_child(effect)
		effect.global_position = pos
		effect.configure("circle", Color.DARK_GRAY)
		effect.scale = Vector2(3, 3)
		effect.play()

func _get_mechanics() -> Dictionary:
	if unit.unit_data.has("levels") and unit.unit_data["levels"].has(str(unit.level)):
		var stats = unit.unit_data["levels"][str(unit.level)]
		return stats.get("mechanics", {})
	return {}

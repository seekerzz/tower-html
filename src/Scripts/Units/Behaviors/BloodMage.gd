extends DefaultBehavior

# 血法师 - 血池降临机制
# 召唤血池区域，敌人受伤友方回血

var blood_pool_scene = null
var active_pools: Array = []

func on_skill_activated():
	if GameManager.grid_manager:
		GameManager.grid_manager.enter_skill_targeting(unit)

func on_skill_executed_at(grid_pos: Vector2i):
	if not GameManager.grid_manager:
		return

	var world_pos = GameManager.grid_manager.get_world_pos_from_grid(grid_pos)

	# 获取等级相关的血池大小和效果
	var mechanics = unit.unit_data.get("levels", {}).get(str(unit.level), {}).get("mechanics", {})
	var pool_size = mechanics.get("pool_size", 1)  # 1x1, 2x2, 3x3
	var heal_efficiency = mechanics.get("heal_efficiency", 1.0)

	# 创建血池效果
	_create_blood_pool(world_pos, pool_size, heal_efficiency)

func _create_blood_pool(center_pos: Vector2, size: int, efficiency: float):
	# 创建血池视觉效果和逻辑
	var pool_duration = 8.0  # 血池持续8秒
	var tile_size = Constants.TILE_SIZE

	# 计算血池覆盖范围
	var pool_radius = (size * tile_size) / 2.0

	# 创建血池视觉节点
	var pool_node = Node2D.new()
	pool_node.name = "BloodPool"
	pool_node.global_position = center_pos

	# 添加视觉表现
	var visual = ColorRect.new()
	visual.color = Color(0.6, 0.0, 0.0, 0.4)  # 半透明血红色
	visual.size = Vector2(pool_radius * 2, pool_radius * 2)
	visual.position = -visual.size / 2

	# 添加边框
	var border = ReferenceRect.new()
	border.border_width = 3.0
	border.editor_only = false
	border.size = visual.size
	border.position = visual.position

	pool_node.add_child(visual)
	pool_node.add_child(border)

	# 添加到场景
	if GameManager.combat_manager:
		GameManager.combat_manager.add_child(pool_node)

		# 存储血池信息
		var pool_data = {
			"node": pool_node,
			"center": center_pos,
			"radius": pool_radius,
			"efficiency": efficiency,
			"timer": pool_duration
		}
		active_pools.append(pool_data)

		# 显示血池降临提示
		GameManager.spawn_floating_text(center_pos, "血池降临!", Color.RED)

		# 启动血池处理
		_start_pool_processing(pool_data)

func _start_pool_processing(pool_data: Dictionary):
	var timer = pool_data.timer
	var node = pool_data.node

	while timer > 0 and is_instance_valid(unit) and is_instance_valid(node):
		await unit.get_tree().create_timer(0.5).timeout
		timer -= 0.5

		if not is_instance_valid(unit) or not is_instance_valid(node):
			break

		# 检查血池范围内的敌人
		var enemies = GameManager.combat_manager.get_tree().get_nodes_in_group("enemies")
		var total_damage_dealt = 0.0

		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue

			var dist = pool_data.center.distance_to(enemy.global_position)
			if dist <= pool_data.radius:
				# 对敌人造成伤害
				var damage = unit.damage * 0.3 * pool_data.efficiency
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage, unit, "magic")
					total_damage_dealt += damage

		# 将造成伤害的一部分转化为治疗
		if total_damage_dealt > 0:
			var heal_amount = total_damage_dealt * 0.5 * pool_data.efficiency
			GameManager.damage_core(-heal_amount)
			GameManager.spawn_floating_text(pool_data.center, "+%d HP" % int(heal_amount), Color.GREEN)

	# 清理血池
	if is_instance_valid(node):
		# 淡出效果
		var tween = node.create_tween()
		tween.tween_property(node, "modulate:a", 0.0, 0.5)
		tween.tween_callback(node.queue_free)

	active_pools.erase(pool_data)

func on_cleanup():
	# 清理所有活跃的血池
	for pool_data in active_pools:
		var node = pool_data.get("node")
		if is_instance_valid(node):
			node.queue_free()
	active_pools.clear()

extends DefaultBehavior

# 牦牛守护 - 守护领域机制
# 自身周围1格范围内友方受到伤害减少5%/10%/15%
# 通过broadcast_buffs给周围友方添加guardian_shield buff
# 被保护的单位在on_damage_taken时检查buff来源并应用减伤

var guardian_range: int = 1  # 守护范围（格）
var damage_reduction: float = 0.05  # 当前等级减伤比例

func on_setup():
	_update_mechanics()

func on_stats_updated():
	_update_mechanics()

func _update_mechanics():
	# 从mechanics获取等级相关配置
	var level = unit.level if unit else 1
	var unit_data = unit.unit_data if unit else {}
	var level_data = unit_data.get("levels", {}).get(str(level), {})
	var mechanics = level_data.get("mechanics", {})

	# 设置守护范围和减伤比例
	guardian_range = mechanics.get("guardian_range", 1)
	damage_reduction = mechanics.get("damage_reduction", 0.05)

func broadcast_buffs():
	# 向周围1格范围内的友方单位应用守护效果
	var neighbors = _get_units_in_range(guardian_range)
	for neighbor in neighbors:
		if neighbor != unit and is_instance_valid(neighbor):
			# 为邻居单位设置伤害减免buff，传入自身作为来源
			neighbor.apply_buff("guardian_shield", unit)

func _get_units_in_range(range_cells: int) -> Array:
	# 获取指定范围内的所有单位
	var list = []
	if !GameManager.grid_manager:
		return list

	var cx = unit.grid_pos.x
	var cy = unit.grid_pos.y
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	# 计算范围内的所有格子坐标
	var range_positions = []
	for dx in range(-range_cells, w + range_cells):
		for dy in range(-range_cells, h + range_cells):
			# 只取边界外围的格子（1格范围内）
			if dx < 0 or dx >= w or dy < 0 or dy >= h:
				range_positions.append(Vector2i(cx + dx, cy + dy))

	for n_pos in range_positions:
		var key = GameManager.grid_manager.get_tile_key(n_pos.x, n_pos.y)
		if GameManager.grid_manager.tiles.has(key):
			var tile = GameManager.grid_manager.tiles[key]
			var u = tile.unit
			if u == null and tile.occupied_by != Vector2i.ZERO:
				var origin_key = GameManager.grid_manager.get_tile_key(tile.occupied_by.x, tile.occupied_by.y)
				if GameManager.grid_manager.tiles.has(origin_key):
					u = GameManager.grid_manager.tiles[origin_key].unit

			if u and is_instance_valid(u) and not (u in list):
				list.append(u)

	return list

# 获取当前减伤比例（供被保护的单位调用）
func get_damage_reduction() -> float:
	return damage_reduction

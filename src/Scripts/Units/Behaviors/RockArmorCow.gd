extends DefaultBehavior

# 岩甲牛 - 护盾坦克
# 核心机制: 岩盾再生 (类似LOL石头人被动)
# 脱离战斗后生成护盾，护盾可吸收伤害
# 正确机制: 脱战5/4/3秒后生成最大生命值10%/15%/20%的护盾

var in_combat: bool = false
var combat_timer: float = 0.0
var shield_amount: float = 0.0
var max_shield: float = 0.0
var out_of_combat_time: float = 5.0  # 脱战所需时间，根据等级变化
var shield_percent: float = 0.1  # 护盾值为最大生命值的百分比，根据等级变化

func on_setup():
	_update_mechanics()
	_calculate_max_shield()
	# 初始时不在战斗中，立即开始计时
	in_combat = false
	combat_timer = 0.0

func on_stats_updated():
	_update_mechanics()
	# 更新最大护盾值
	_calculate_max_shield()
	# 确保当前护盾不超过最大值
	shield_amount = min(shield_amount, max_shield)

func _update_mechanics():
	# 从mechanics获取等级相关配置
	var level = unit.level
	var unit_data = unit.unit_data
	var level_data = unit_data.get("levels", {}).get(str(level), {})
	var mechanics = level_data.get("mechanics", {})

	# 设置脱战时间和护盾百分比
	out_of_combat_time = mechanics.get("out_of_combat_time", 5.0)
	shield_percent = mechanics.get("shield_percent", 0.1)

func _calculate_max_shield():
	max_shield = unit.max_hp * shield_percent

func on_tick(delta: float):
	if not in_combat:
		# 不在战斗中，计时器增加
		combat_timer += delta
		if combat_timer >= out_of_combat_time:
			# 脱战时间达到，生成护盾
			_regenerate_shield()
			# 重置计时器，避免重复触发
			combat_timer = 0.0

func _regenerate_shield():
	_calculate_max_shield()
	# 只有护盾未满时才显示效果
	if shield_amount < max_shield:
		shield_amount = max_shield
		GameManager.spawn_floating_text(unit.global_position, "岩盾激活!", Color.GRAY)
		_show_shield_effect()

func _show_shield_effect():
	# 创建护盾视觉效果
	if not unit.visual_holder:
		return

	# 如果已经有护盾效果，不重复创建
	var existing_effect = unit.visual_holder.get_node_or_null("ShieldEffect")
	if existing_effect:
		return

	var shield_effect = ReferenceRect.new()
	shield_effect.name = "ShieldEffect"
	shield_effect.border_width = 2.0
	shield_effect.modulate = Color(0.5, 0.5, 0.5, 0.8)
	shield_effect.editor_only = false
	shield_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var size = unit.unit_data.get("size", Vector2i(1, 1))
	var target_size = Vector2(size.x * Constants.TILE_SIZE - 8, size.y * Constants.TILE_SIZE - 8)
	shield_effect.size = target_size
	shield_effect.position = -(target_size / 2)

	unit.visual_holder.add_child(shield_effect)

	# 护盾闪烁效果
	var tween = unit.create_tween()
	tween.tween_property(shield_effect, "modulate", Color(0.7, 0.7, 0.7, 1.0), 0.3)
	tween.tween_property(shield_effect, "modulate", Color(0.5, 0.5, 0.5, 0.8), 0.3)
	tween.set_loops(3)

func _update_shield_visual():
	if not unit.visual_holder:
		return

	var shield_effect = unit.visual_holder.get_node_or_null("ShieldEffect")
	if shield_amount > 0:
		if not shield_effect:
			_show_shield_effect()
	else:
		if shield_effect:
			shield_effect.queue_free()

func _enter_combat():
	# 进入战斗状态，重置计时器
	in_combat = true
	combat_timer = 0.0

func _exit_combat():
	# 退出战斗状态，开始脱战计时
	in_combat = false
	combat_timer = 0.0

func on_damage_taken(amount: float, source: Node2D) -> float:
	# 进入战斗状态
	_enter_combat()

	# 如果有护盾，优先吸收伤害
	if shield_amount > 0:
		var absorbed = min(shield_amount, amount)
		shield_amount -= absorbed
		amount -= absorbed

		# 显示护盾吸收效果
		if absorbed > 0:
			GameManager.spawn_floating_text(unit.global_position, "护盾 -%d" % int(absorbed), Color.GRAY)

		# 如果护盾被打破
		if shield_amount <= 0 and absorbed > 0:
			GameManager.spawn_floating_text(unit.global_position, "岩盾破碎!", Color.RED)

		# 更新护盾视觉效果
		_update_shield_visual()

	return amount

func on_combat_tick(delta: float) -> bool:
	# 造成伤害时进入战斗状态
	_enter_combat()
	# 返回false让Unit.gd处理默认攻击逻辑
	return false

func get_current_shield() -> float:
	return shield_amount

func get_max_shield() -> float:
	return max_shield

func on_cleanup():
	# 清理护盾视觉效果
	if unit.visual_holder:
		var shield_effect = unit.visual_holder.get_node_or_null("ShieldEffect")
		if shield_effect:
			shield_effect.queue_free()

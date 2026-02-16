extends DefaultBehavior

# 菌菇治愈者 - 过量转化机制
# 核心受到治疗时，超出上限部分转化为延迟回血
# 实现方式：通过监听核心生命值变化来检测治疗事件

var delayed_heal_queue: Array = []  # 存储延迟回血条目: {amount: float, time_left: float}
var heal_release_timer: float = 0.0
var heal_release_interval: float = 1.0  # 每秒释放一次延迟回血
var last_core_health: float = 0.0  # 用于检测核心生命值变化
var conversion_rate: float = 0.8  # 转化比例
var has_enhancement: bool = false  # L3是否有增强效果

func on_setup():
	_update_mechanics()
	# 初始化最后记录的核心生命值
	if GameManager:
		last_core_health = GameManager.core_health

func on_stats_updated():
	_update_mechanics()

func _update_mechanics():
	# 从mechanics获取等级相关配置
	var level = unit.level if unit else 1
	var unit_data = unit.unit_data if unit else {}
	var level_data = unit_data.get("levels", {}).get(str(level), {})
	var mechanics = level_data.get("mechanics", {})

	# 设置转化比例
	conversion_rate = mechanics.get("conversion_rate", 0.8)
	has_enhancement = level >= 3 and mechanics.get("enhancement", 1.0) > 1.0

func on_tick(delta: float):
	# 检测核心生命值变化（治疗事件）
	if GameManager and GameManager.core_health > last_core_health:
		var heal_amount = GameManager.core_health - last_core_health
		_process_core_heal(heal_amount)
		last_core_health = GameManager.core_health
	elif GameManager:
		last_core_health = GameManager.core_health

	# 处理延迟回血队列的释放
	heal_release_timer -= delta
	if heal_release_timer <= 0:
		_release_delayed_heal()
		heal_release_timer = heal_release_interval

	# 更新队列中每个条目的倒计时
	for entry in delayed_heal_queue:
		entry.time_left -= delta

func _process_core_heal(heal_amount: float):
	# 计算核心当前缺失的生命值（在治疗前）
	var missing_hp = GameManager.max_core_health - GameManager.core_health

	# 计算溢出量（实际治疗量减去缺失的生命值）
	# 如果治疗量大于缺失的生命值，超出部分就是溢出
	var overflow = 0.0
	if heal_amount > missing_hp:
		overflow = heal_amount - missing_hp

	if overflow > 0:
		# 计算要转化的量
		var to_convert = overflow * conversion_rate

		# L3效果：转化量增加50%
		if has_enhancement:
			to_convert *= 1.5

		# 存储到延迟回血队列（延迟3秒后释放）
		var entry = {
			"amount": to_convert,
			"time_left": 3.0  # 3秒延迟
		}
		delayed_heal_queue.append(entry)

		# 显示转化提示
		GameManager.spawn_floating_text(unit.global_position, "转化 %d" % int(to_convert), Color.MEDIUM_PURPLE)

func _release_delayed_heal():
	# 释放到期的延迟回血
	var total_to_release: float = 0.0
	var remaining_queue: Array = []

	for entry in delayed_heal_queue:
		if entry.time_left <= 0:
			total_to_release += entry.amount
		else:
			remaining_queue.append(entry)

	delayed_heal_queue = remaining_queue

	if total_to_release > 0:
		# 应用延迟回血
		var actual_heal = _apply_heal_to_core(total_to_release)
		if actual_heal > 0:
			GameManager.spawn_floating_text(unit.global_position, "+%d" % int(actual_heal), Color.LIGHT_GREEN)

func _apply_heal_to_core(amount: float) -> float:
	# 计算实际可以回复的生命值（不超过上限）
	var missing_hp = GameManager.max_core_health - GameManager.core_health
	var actual_heal = min(amount, missing_hp)

	if actual_heal > 0:
		GameManager.damage_core(-actual_heal)
		# 更新last_core_health以避免重复处理
		last_core_health = GameManager.core_health

	return actual_heal

func on_skill_activated():
	# 主动技能：立即释放所有存储的延迟回血
	var total_delayed: float = 0.0
	for entry in delayed_heal_queue:
		total_delayed += entry.amount

	delayed_heal_queue.clear()

	if total_delayed > 0:
		var actual_heal = _apply_heal_to_core(total_delayed)
		if actual_heal > 0:
			GameManager.spawn_floating_text(unit.global_position, "爆发 +%d!" % int(actual_heal), Color.GREEN)

	# 高亮显示技能激活
	unit.set_highlight(true, Color.LIGHT_GREEN)
	await unit.get_tree().create_timer(2.0).timeout
	unit.set_highlight(false)

# 获取当前存储的延迟回血总量
func get_stored_heal_amount() -> float:
	var total: float = 0.0
	for entry in delayed_heal_queue:
		total += entry.amount
	return total

func on_cleanup():
	# 清理队列
	delayed_heal_queue.clear()

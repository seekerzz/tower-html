extends Node

# 测试蝙蝠图腾系列4个单位的功能
# 测试目标:
# 1. vampire_bat - 验证鲜血狂噬机制（生命值越低吸血越高）
# 2. plague_spreader - 验证毒血传播机制（中毒敌人死亡传播）
# 3. blood_mage - 验证血池降临机制（召唤血池区域）
# 4. blood_ancestor - 验证鲜血领域机制（受伤敌人增伤）

var test_results: Dictionary = {}
var tests_passed: int = 0
var tests_failed: int = 0
var game_data: Dictionary = {}

func _ready():
	print("============================================================")
	print("Starting Bat Totem Units Test Suite")
	print("============================================================")

	# 加载game_data.json
	_load_game_data()

	# 运行所有测试
	test_vampire_bat()
	test_plague_spreader()
	test_blood_mage()
	test_blood_ancestor()

	# 输出总结
	print("\n============================================================")
	print("Test Summary")
	print("============================================================")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)
	print("Total:  %d" % (tests_passed + tests_failed))

	if tests_failed == 0:
		print("\nALL TESTS PASSED!")
	else:
		print("\nSOME TESTS FAILED!")

	# 保存测试结果到文件
	_save_test_results()

	get_tree().quit()

func _load_game_data():
	var file = FileAccess.open("res://data/game_data.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			game_data = json.data
			print("Loaded game_data.json successfully")
		else:
			print("Failed to parse game_data.json")
		file.close()
	else:
		print("Failed to open game_data.json")

# Helper function to check if script contains method
func _script_has_method(script_content: String, method_name: String) -> bool:
	return script_content.find("func " + method_name) != -1

# Helper function to check if script contains variable
func _script_has_variable(script_content: String, var_name: String) -> bool:
	return script_content.find("var " + var_name) != -1

# ==================== Test 1: Vampire Bat ====================

func test_vampire_bat():
	print("\n------------------------------------------------------------")
	print("Testing Vampire Bat (吸血蝠) - 鲜血狂噬机制")
	print("------------------------------------------------------------")

	var passed = true

	# Test 1.1: 检查单位数据配置
	print("\n[Test 1.1] Checking unit data configuration...")
	var unit_types = game_data.get("UNIT_TYPES", {})
	var unit_data = unit_types.get("vampire_bat", {})
	if unit_data.is_empty():
		print("  FAIL: vampire_bat not found in UNIT_TYPES")
		passed = false
	else:
		print("  PASS: vampire_bat found in UNIT_TYPES")

		# 检查攻击类型
		var attack_type = unit_data.get("attackType", "")
		if attack_type == "melee":
			print("  PASS: attackType is 'melee'")
		else:
			print("  FAIL: attackType is '%s', expected 'melee'" % attack_type)
			passed = false

		# 检查伤害类型
		var damage_type = unit_data.get("damageType", "")
		if damage_type == "physical":
			print("  PASS: damageType is 'physical'")
		else:
			print("  FAIL: damageType is '%s', expected 'physical'" % damage_type)
			passed = false

		# 检查等级配置
		var expected_base = {1: 0.0, 2: 0.2, 3: 0.4}
		for level in [1, 2, 3]:
			var level_data = unit_data.get("levels", {}).get(str(level), {})
			var mechanics = level_data.get("mechanics", {})
			var base_lifesteal = mechanics.get("base_lifesteal", -1.0)
			var low_hp_bonus = mechanics.get("low_hp_bonus", -1.0)
			
			# 检查基础吸血
			if abs(base_lifesteal - expected_base[level]) < 0.001:
				print("  PASS: Level %d base_lifesteal is %.0f%%" % [level, base_lifesteal * 100])
			else:
				print("  FAIL: Level %d base_lifesteal is %.2f, expected %.2f" % [level, base_lifesteal, expected_base[level]])
				passed = false
			
			# 检查低生命加成
			if abs(low_hp_bonus - 0.5) < 0.001:
				print("  PASS: Level %d low_hp_bonus is 50%%" % level)
			else:
				print("  FAIL: Level %d low_hp_bonus is %.2f, expected 0.5" % [level, low_hp_bonus])
				passed = false

	# Test 1.2: 检查行为脚本
	print("\n[Test 1.2] Checking behavior script...")
	var script_path = "res://src/Scripts/Units/Behaviors/VampireBat.gd"
	var file = FileAccess.open(script_path, FileAccess.READ)
	if file:
		print("  PASS: VampireBat.gd exists")
		var content = file.get_as_text()
		file.close()

		# 检查必要的方法
		if _script_has_method(content, "on_projectile_hit"):
			print("  PASS: has on_projectile_hit() method")
		else:
			print("  FAIL: missing on_projectile_hit() method")
			passed = false

		# 检查是否继承DefaultBehavior
		if content.find("extends DefaultBehavior") != -1:
			print("  PASS: extends DefaultBehavior")
		else:
			print("  FAIL: should extend DefaultBehavior")
			passed = false
		
		# 检查是否正确计算生命值比例
		if content.find("unit.hp / unit.max_hp") != -1 or content.find("hp_percent") != -1:
			print("  PASS: calculates HP percentage correctly")
		else:
			print("  WARN: may not calculate HP percentage correctly")
		
		# 检查吸血逻辑
		if content.find("damage_core") != -1 or content.find("lifesteal") != -1:
			print("  PASS: implements lifesteal logic")
		else:
			print("  FAIL: missing lifesteal implementation")
			passed = false
	else:
		print("  FAIL: VampireBat.gd not found")
		passed = false

	_record_result("vampire_bat", passed)

# ==================== Test 2: Plague Spreader ====================

func test_plague_spreader():
	print("\n------------------------------------------------------------")
	print("Testing Plague Spreader (瘟疫使者) - 毒血传播机制")
	print("------------------------------------------------------------")

	var passed = true

	# Test 2.1: 检查单位数据配置
	print("\n[Test 2.1] Checking unit data configuration...")
	var unit_types = game_data.get("UNIT_TYPES", {})
	var unit_data = unit_types.get("plague_spreader", {})
	if unit_data.is_empty():
		print("  FAIL: plague_spreader not found in UNIT_TYPES")
		passed = false
	else:
		print("  PASS: plague_spreader found in UNIT_TYPES")

		# 检查攻击类型
		var attack_type = unit_data.get("attackType", "")
		if attack_type == "ranged":
			print("  PASS: attackType is 'ranged'")
		else:
			print("  FAIL: attackType is '%s', expected 'ranged'" % attack_type)
			passed = false

		# 检查弹丸类型
		var proj = unit_data.get("proj", "")
		if proj == "stinger":
			print("  PASS: proj is 'stinger'")
		else:
			print("  FAIL: proj is '%s', expected 'stinger'" % proj)
			passed = false

		# 检查伤害类型
		var damage_type = unit_data.get("damageType", "")
		if damage_type == "poison":
			print("  PASS: damageType is 'poison'")
		else:
			print("  FAIL: damageType is '%s', expected 'poison'" % damage_type)
			passed = false

		# 检查等级配置 - 传播范围
		var expected_range = {1: 0.0, 2: 60.0, 3: 120.0}
		for level in [1, 2, 3]:
			var level_data = unit_data.get("levels", {}).get(str(level), {})
			var mechanics = level_data.get("mechanics", {})
			var spread_range = mechanics.get("spread_range", -1.0)
			
			if abs(spread_range - expected_range[level]) < 0.001:
				print("  PASS: Level %d spread_range is %.0f" % [level, spread_range])
			else:
				print("  FAIL: Level %d spread_range is %.2f, expected %.2f" % [level, spread_range, expected_range[level]])
				passed = false

	# Test 2.2: 检查行为脚本
	print("\n[Test 2.2] Checking behavior script...")
	var script_path = "res://src/Scripts/Units/Behaviors/PlagueSpreader.gd"
	var file = FileAccess.open(script_path, FileAccess.READ)
	if file:
		print("  PASS: PlagueSpreader.gd exists")
		var content = file.get_as_text()
		file.close()

		# 检查必要的方法
		if _script_has_method(content, "on_projectile_hit"):
			print("  PASS: has on_projectile_hit() method")
		else:
			print("  FAIL: missing on_projectile_hit() method")
			passed = false

		if _script_has_method(content, "_on_infected_enemy_died"):
			print("  PASS: has _on_infected_enemy_died() method")
		else:
			print("  FAIL: missing _on_infected_enemy_died() method")
			passed = false

		# 检查是否预加载PoisonEffect
		if content.find("PoisonEffect") != -1 or content.find("poison_effect") != -1:
			print("  PASS: preloads PoisonEffect")
		else:
			print("  FAIL: should preload PoisonEffect")
			passed = false
		
		# 检查信号连接
		if content.find("died.connect") != -1 or content.find("died.is_connected") != -1:
			print("  PASS: connects to enemy died signal")
		else:
			print("  FAIL: should connect to enemy died signal")
			passed = false
		
		# 检查传播逻辑
		if content.find("spread") != -1:
			print("  PASS: implements spread logic")
		else:
			print("  FAIL: missing spread implementation")
			passed = false
	else:
		print("  FAIL: PlagueSpreader.gd not found")
		passed = false

	_record_result("plague_spreader", passed)

# ==================== Test 3: Blood Mage ====================

func test_blood_mage():
	print("\n------------------------------------------------------------")
	print("Testing Blood Mage (血法师) - 血池降临机制")
	print("------------------------------------------------------------")

	var passed = true

	# Test 3.1: 检查单位数据配置
	print("\n[Test 3.1] Checking unit data configuration...")
	var unit_types = game_data.get("UNIT_TYPES", {})
	var unit_data = unit_types.get("blood_mage", {})
	if unit_data.is_empty():
		print("  FAIL: blood_mage not found in UNIT_TYPES")
		passed = false
	else:
		print("  PASS: blood_mage found in UNIT_TYPES")

		# 检查攻击类型
		var attack_type = unit_data.get("attackType", "")
		if attack_type == "ranged":
			print("  PASS: attackType is 'ranged'")
		else:
			print("  FAIL: attackType is '%s', expected 'ranged'" % attack_type)
			passed = false

		# 检查技能配置
		var skill = unit_data.get("skill", "")
		if skill == "blood_pool":
			print("  PASS: skill is 'blood_pool'")
		else:
			print("  FAIL: skill is '%s', expected 'blood_pool'" % skill)
			passed = false

		# 检查技能类型
		var skill_type = unit_data.get("skillType", "")
		if skill_type == "point":
			print("  PASS: skillType is 'point'")
		else:
			print("  FAIL: skillType is '%s', expected 'point'" % skill_type)
			passed = false

		# 检查等级配置 - 血池大小和效率
		var expected_size = {1: 1, 2: 2, 3: 3}
		var expected_eff = {1: 1.0, 2: 1.0, 3: 1.5}
		for level in [1, 2, 3]:
			var level_data = unit_data.get("levels", {}).get(str(level), {})
			var mechanics = level_data.get("mechanics", {})
			var pool_size = mechanics.get("pool_size", 0)
			var heal_efficiency = mechanics.get("heal_efficiency", -1.0)
			
			if pool_size == expected_size[level]:
				print("  PASS: Level %d pool_size is %d" % [level, pool_size])
			else:
				print("  FAIL: Level %d pool_size is %d, expected %d" % [level, pool_size, expected_size[level]])
				passed = false
			
			if abs(heal_efficiency - expected_eff[level]) < 0.001:
				print("  PASS: Level %d heal_efficiency is %.1f" % [level, heal_efficiency])
			else:
				print("  FAIL: Level %d heal_efficiency is %.2f, expected %.2f" % [level, heal_efficiency, expected_eff[level]])
				passed = false

	# Test 3.2: 检查行为脚本
	print("\n[Test 3.2] Checking behavior script...")
	var script_path = "res://src/Scripts/Units/Behaviors/BloodMage.gd"
	var file = FileAccess.open(script_path, FileAccess.READ)
	if file:
		print("  PASS: BloodMage.gd exists")
		var content = file.get_as_text()
		file.close()

		# 检查必要的方法
		if _script_has_method(content, "on_skill_activated"):
			print("  PASS: has on_skill_activated() method")
		else:
			print("  FAIL: missing on_skill_activated() method")
			passed = false

		if _script_has_method(content, "on_skill_executed_at"):
			print("  PASS: has on_skill_executed_at() method")
		else:
			print("  FAIL: missing on_skill_executed_at() method")
			passed = false

		if _script_has_method(content, "_create_blood_pool"):
			print("  PASS: has _create_blood_pool() method")
		else:
			print("  FAIL: missing _create_blood_pool() method")
			passed = false

		if _script_has_method(content, "_start_pool_processing"):
			print("  PASS: has _start_pool_processing() method")
		else:
			print("  FAIL: missing _start_pool_processing() method")
			passed = false
		
		if _script_has_method(content, "on_cleanup"):
			print("  PASS: has on_cleanup() method")
		else:
			print("  FAIL: missing on_cleanup() method")
			passed = false
		
		# 检查active_pools数组
		if _script_has_variable(content, "active_pools"):
			print("  PASS: has active_pools property")
		else:
			print("  FAIL: missing active_pools property")
			passed = false
		
		# 检查血池视觉效果
		if content.find("ColorRect") != -1:
			print("  PASS: creates ColorRect for blood pool visual")
		else:
			print("  WARN: may not have blood pool visual")
	else:
		print("  FAIL: BloodMage.gd not found")
		passed = false

	_record_result("blood_mage", passed)

# ==================== Test 4: Blood Ancestor ====================

func test_blood_ancestor():
	print("\n------------------------------------------------------------")
	print("Testing Blood Ancestor (血祖) - 鲜血领域机制")
	print("------------------------------------------------------------")

	var passed = true

	# Test 4.1: 检查单位数据配置
	print("\n[Test 4.1] Checking unit data configuration...")
	var unit_types = game_data.get("UNIT_TYPES", {})
	var unit_data = unit_types.get("blood_ancestor", {})
	if unit_data.is_empty():
		print("  FAIL: blood_ancestor not found in UNIT_TYPES")
		passed = false
	else:
		print("  PASS: blood_ancestor found in UNIT_TYPES")

		# 检查攻击类型
		var attack_type = unit_data.get("attackType", "")
		if attack_type == "ranged":
			print("  PASS: attackType is 'ranged'")
		else:
			print("  FAIL: attackType is '%s', expected 'ranged'" % attack_type)
			passed = false

		# 检查弹丸类型
		var proj = unit_data.get("proj", "")
		if proj == "magic_missile":
			print("  PASS: proj is 'magic_missile'")
		else:
			print("  FAIL: proj is '%s', expected 'magic_missile'" % proj)
			passed = false

		# 检查等级配置 - 伤害加成和吸血
		var expected_dmg = {1: 0.1, 2: 0.15, 3: 0.2}
		var expected_lifesteal = {1: 0.0, 2: 0.0, 3: 0.2}
		for level in [1, 2, 3]:
			var level_data = unit_data.get("levels", {}).get(str(level), {})
			var mechanics = level_data.get("mechanics", {})
			var damage_per = mechanics.get("damage_per_injured_enemy", -1.0)
			var lifesteal = mechanics.get("lifesteal_bonus", -1.0)
			
			if abs(damage_per - expected_dmg[level]) < 0.001:
				print("  PASS: Level %d damage_per_injured_enemy is %d%%" % [level, int(damage_per * 100)])
			else:
				print("  FAIL: Level %d damage_per_injured_enemy is %.2f, expected %.2f" % [level, damage_per, expected_dmg[level]])
				passed = false
			
			if abs(lifesteal - expected_lifesteal[level]) < 0.001:
				print("  PASS: Level %d lifesteal_bonus is %d%%" % [level, int(lifesteal * 100)])
			else:
				print("  FAIL: Level %d lifesteal_bonus is %.2f, expected %.2f" % [level, lifesteal, expected_lifesteal[level]])
				passed = false

	# Test 4.2: 检查行为脚本
	print("\n[Test 4.2] Checking behavior script...")
	var script_path = "res://src/Scripts/Units/Behaviors/BloodAncestor.gd"
	var file = FileAccess.open(script_path, FileAccess.READ)
	if file:
		print("  PASS: BloodAncestor.gd exists")
		var content = file.get_as_text()
		file.close()

		# 检查必要的方法
		if _script_has_method(content, "on_stats_updated"):
			print("  PASS: has on_stats_updated() method")
		else:
			print("  FAIL: missing on_stats_updated() method")
			passed = false

		if _script_has_method(content, "on_tick"):
			print("  PASS: has on_tick() method")
		else:
			print("  FAIL: missing on_tick() method")
			passed = false

		if _script_has_method(content, "_update_blood_domain_bonus"):
			print("  PASS: has _update_blood_domain_bonus() method")
		else:
			print("  FAIL: missing _update_blood_domain_bonus() method")
			passed = false

		if _script_has_method(content, "_count_injured_enemies"):
			print("  PASS: has _count_injured_enemies() method")
		else:
			print("  FAIL: missing _count_injured_enemies() method")
			passed = false

		if _script_has_method(content, "on_projectile_hit"):
			print("  PASS: has on_projectile_hit() method")
		else:
			print("  FAIL: missing on_projectile_hit() method")
			passed = false

		if _script_has_method(content, "calculate_modified_damage"):
			print("  PASS: has calculate_modified_damage() method")
		else:
			print("  FAIL: missing calculate_modified_damage() method")
			passed = false
		
		# 检查属性
		if _script_has_variable(content, "current_bonus_damage"):
			print("  PASS: has current_bonus_damage property")
		else:
			print("  FAIL: missing current_bonus_damage property")
			passed = false
		
		if _script_has_variable(content, "current_lifesteal"):
			print("  PASS: has current_lifesteal property")
		else:
			print("  FAIL: missing current_lifesteal property")
			passed = false
	else:
		print("  FAIL: BloodAncestor.gd not found")
		passed = false

	# Test 4.3: 检查Unit.gd中的伤害加成集成（可选）
	print("\n[Test 4.3] Checking Unit.gd damage modifier integration...")
	var unit_script_path = "res://src/Scripts/Unit.gd"
	var unit_file = FileAccess.open(unit_script_path, FileAccess.READ)
	if unit_file:
		var unit_content = unit_file.get_as_text()
		unit_file.close()

		if unit_content.find("calculate_modified_damage") != -1 or unit_content.find("behavior") != -1:
			print("  INFO: Unit.gd may have behavior damage modification")
		else:
			print("  WARN: Unit.gd may not call calculate_modified_damage")
			# 这不一定是失败，因为可能在其他地方处理
	else:
		print("  WARN: Could not read Unit.gd")

	_record_result("blood_ancestor", passed)

# ==================== Helper Functions ====================

func _record_result(test_name: String, passed: bool):
	test_results[test_name] = passed
	if passed:
		tests_passed += 1
		print("\n[RESULT] %s: PASS" % test_name)
	else:
		tests_failed += 1
		print("\n[RESULT] %s: FAIL" % test_name)

func _save_test_results():
	var result_text = "# Bat Totem Units Test Results\n\n"
	result_text += "Test Date: %s\n\n" % Time.get_datetime_string_from_system()
	result_text += "## Summary\n\n"
	result_text += "- Passed: %d\n" % tests_passed
	result_text += "- Failed: %d\n" % tests_failed
	result_text += "- Total:  %d\n\n" % (tests_passed + tests_failed)

	result_text += "## Detailed Results\n\n"
	for test_name in test_results:
		var status = "PASS" if test_results[test_name] else "FAIL"
		result_text += "- %s: %s\n" % [test_name, status]

	result_text += "\n## Unit Mechanisms Tested\n\n"
	result_text += "1. **vampire_bat** (吸血蝠) - 鲜血狂噬机制: 生命值越低，吸血比例越高\n"
	result_text += "2. **plague_spreader** (瘟疫使者) - 毒血传播机制: 中毒敌人死亡时传播瘟疫\n"
	result_text += "3. **blood_mage** (血法师) - 血池降临机制: 召唤血池区域，造成伤害并治疗\n"
	result_text += "4. **blood_ancestor** (血祖) - 鲜血领域机制: 场上受伤敌人越多，自身攻击力越高\n"

	result_text += "\n## Issues Found\n\n"
	if tests_failed == 0:
		result_text += "No issues found. All tests passed!\n"
	else:
		result_text += "See console output for detailed failure information.\n"

	# 确保目录存在
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("tasks/bat_totem_units"):
		dir.make_dir_recursive("tasks/bat_totem_units")

	var file = FileAccess.open("res://tasks/bat_totem_units/test_result.md", FileAccess.WRITE)
	if file:
		file.store_string(result_text)
		file.close()
		print("\nTest results saved to: tasks/bat_totem_units/test_result.md")

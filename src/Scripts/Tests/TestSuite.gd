extends RefCounted

func get_test_config(case_id: String) -> Dictionary:
	match case_id:
		"test_soul_system":
			return {
				"id": "test_soul_system",
				"core_type": "wolf_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 10.0,
				"units": [
					{"id": "squirrel", "x": 0, "y": 1}
				]
			}
		"test_cow_squirrel":
			return {
				"id": "test_cow_squirrel",
				"core_type": "cow_totem",
				"initial_gold": 1000,
				"start_wave_index": 2,
				"duration": 10.0,
				"units": [
					{"id": "squirrel", "x": 0, "y": 2}
				]
			}
		"test_butterfly_phoenix":
			return {
				"id": "test_butterfly_phoenix",
				"core_type": "butterfly_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 10.0,
				"units": [
					{"id": "phoenix", "x": 0, "y": 1}
				],
				"scheduled_actions": [
					{
						"time": 5.0,
						"type": "skill",
						"source": "phoenix",
						"target": {"x": -2, "y": -2}
					}
				]
			}
		"test_viper_strategy":
			return {
				"id": "test_viper_strategy",
				"core_type": "viper_totem",
				"initial_gold": 2000,
				"start_wave_index": 1,
				"end_condition": "wave_end_or_fail",
				"units": [
					{"id": "squirrel", "x": 0, "y": 1},
					{"id": "viper", "x": -1, "y": 0}
				],
				"setup_actions": [
					{
						"type": "spawn_trap",
						"trap_id": "poison_trap",
						"strategy": "random_valid"
					},
					{
						"type": "apply_buff",
						"buff_id": "poison",
						"target_unit_id": "squirrel"
					}
				]
			}
		"test_bleed_lifesteal":
			return {
				"id": "test_bleed_lifesteal",
				"core_type": "bat_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 8.0,
				"units": [
					{"id": "mosquito", "x": 0, "y": 1},
					{"id": "mosquito", "x": 0, "y": -1},
					{"id": "mosquito", "x": 1, "y": 0},
					{"id": "mosquito", "x": -1, "y": 0}
				]
			}
		"test_taunt_system":
			return {
				"id": "test_taunt_system",
				"core_type": "cow_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [
					{"id": "yak_guardian", "x": 0, "y": 1}
				]
			}
		"test_summon_system":
			return {
				"id": "test_summon_system",
				"core_type": "viper_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 30.0,
				"units": [],
				"scheduled_actions": [
					{
						"time": 1.0,
						"type": "summon_test",
						"summon_type": "spiderling",
						"position": {"x": 0, "y": 1}
					}
				]
			}
		"test_eagle_kestrel":
			return {
				"id": "test_eagle_kestrel",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "kestrel", "x": 0, "y": 1}]
			}
		"test_eagle_owl":
			return {
				"id": "test_eagle_owl",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [
					{"id": "owl", "x": 0, "y": 1},
					{"id": "kestrel", "x": 0, "y": 0}
				]
			}
		"test_eagle_magpie":
			return {
				"id": "test_eagle_magpie",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "magpie", "x": 0, "y": 1}]
			}
		"test_eagle_pigeon":
			return {
				"id": "test_eagle_pigeon",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "pigeon", "x": 0, "y": 1}]
			}
		"test_shop_faction_refresh":
			return {
				"id": "test_shop_faction_refresh",
				"core_type": "wolf_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 5.0,
				"test_shop": true,
				"validate_shop_faction": "wolf_totem"
			}
		"test_enemy_death_no_duplicate":
			return {
				"id": "test_enemy_death_no_duplicate",
				"core_type": "wolf_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 5.0,
				"units": [
					{"id": "tiger", "x": 0, "y": 0}
				],
				"scheduled_actions": [
					{
						"time": 2.0,
						"type": "test_enemy_death"
					}
				],
				"description": "测试敌人死亡时不会重复调用die()函数，防止重复添加魂魄/金币"
			}
		# ========== 牛图腾流派单位测试 (8个单位) ==========
		"test_cow_totem_plant":
			return {
				"id": "test_cow_totem_plant",
				"core_type": "cow_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "plant", "x": 0, "y": 1}]
			}
		"test_cow_totem_iron_turtle":
			return {
				"id": "test_cow_totem_iron_turtle",
				"core_type": "cow_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "iron_turtle", "x": 0, "y": 1}]
			}
		"test_cow_totem_hedgehog":
			return {
				"id": "test_cow_totem_hedgehog",
				"core_type": "cow_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "hedgehog", "x": 0, "y": 1}]
			}
		"test_cow_totem_yak_guardian":
			return {
				"id": "test_cow_totem_yak_guardian",
				"core_type": "cow_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "yak_guardian", "x": 0, "y": 1}]
			}
		"test_cow_totem_cow_golem":
			return {
				"id": "test_cow_totem_cow_golem",
				"core_type": "cow_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "cow_golem", "x": 0, "y": 1}]
			}
		"test_cow_totem_rock_armor_cow":
			return {
				"id": "test_cow_totem_rock_armor_cow",
				"core_type": "cow_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "rock_armor_cow", "x": 0, "y": 1}]
			}
		"test_cow_totem_mushroom_healer":
			return {
				"id": "test_cow_totem_mushroom_healer",
				"core_type": "cow_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "mushroom_healer", "x": 0, "y": 1}]
			}
		"test_cow_totem_cow":
			return {
				"id": "test_cow_totem_cow",
				"core_type": "cow_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "cow", "x": 0, "y": 1}]
			}
		# ========== 蝙蝠图腾流派单位测试 (5个单位) ==========
		"test_bat_totem_mosquito":
			return {
				"id": "test_bat_totem_mosquito",
				"core_type": "bat_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "mosquito", "x": 0, "y": 1}]
			}
		"test_bat_totem_vampire_bat":
			return {
				"id": "test_bat_totem_vampire_bat",
				"core_type": "bat_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "vampire_bat", "x": 0, "y": 1}]
			}
		"test_bat_totem_plague_spreader":
			return {
				"id": "test_bat_totem_plague_spreader",
				"core_type": "bat_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "plague_spreader", "x": 0, "y": 1}]
			}
		"test_bat_totem_blood_mage":
			return {
				"id": "test_bat_totem_blood_mage",
				"core_type": "bat_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 20.0,
				"units": [{"id": "blood_mage", "x": 0, "y": 1}],
				"scheduled_actions": [
					{"type": "skill", "time": 5.0, "source": "blood_mage", "target": {"x": 2, "y": 2}}
				]
			}
		"test_bat_totem_blood_mage_skill":
			return {
				"id": "test_bat_totem_blood_mage_skill",
				"core_type": "bat_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 25.0,
				"units": [{"id": "blood_mage", "x": 0, "y": 1}],
				"scheduled_actions": [
					{"type": "skill", "time": 3.0, "source": "blood_mage", "target": {"x": 2, "y": 2}},
					{"type": "skill", "time": 12.0, "source": "blood_mage", "target": {"x": -2, "y": 2}}
				]
			}
		"test_bat_totem_blood_ancestor":
			return {
				"id": "test_bat_totem_blood_ancestor",
				"core_type": "bat_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "blood_ancestor", "x": 0, "y": 1}]
			}
		# TEST-BAT-vampire_bat 吸血蝠自动化测试
		"test_vampire_bat_lv1_lifesteal":
			return {
				"id": "test_vampire_bat_lv1_lifesteal",
				"core_type": "bat_totem",
				"duration": 10.0,
				"units": [
					{"id": "vampire_bat", "x": 0, "y": 1, "level": 1, "hp": 200, "max_hp": 200}
				],
				"enemies": [
					{"type": "basic_enemy", "count": 5, "hp": 100}
				],
				"scheduled_actions": [
					{"time": 2.0, "type": "record_lifesteal", "source_unit_id": "vampire_bat", "label": "full_hp"},
					{"time": 5.0, "type": "damage_unit", "unit_id": "vampire_bat", "amount": 150},
					{"time": 8.0, "type": "record_lifesteal", "source_unit_id": "vampire_bat", "label": "low_hp"}
				],
				"expected_behavior": "生命值越低吸血越高，最低生命时+50%吸血"
			}
		"test_vampire_bat_lv2_lifesteal":
			return {
				"id": "test_vampire_bat_lv2_lifesteal",
				"core_type": "bat_totem",
				"duration": 10.0,
				"units": [
					{"id": "vampire_bat", "x": 0, "y": 1, "level": 2, "hp": 300, "max_hp": 300}
				],
				"enemies": [
					{"type": "basic_enemy", "count": 5, "hp": 100}
				],
				"scheduled_actions": [
					{"time": 2.0, "type": "record_lifesteal", "source_unit_id": "vampire_bat", "label": "full_hp"}
				],
				"expected_behavior": "基础吸血+20%，生命值越低吸血越高"
			}
		"test_vampire_bat_lv3_bleed_damage":
			return {
				"id": "test_vampire_bat_lv3_bleed_damage",
				"core_type": "bat_totem",
				"start_wave_index": 1,
				"initial_gold": 10000, # High gold just in case
				"core_health": 10000, # Prevent Game Over
				"duration": 25.0,
				"units": [
					{"id": "vampire_bat", "x": 0, "y": 1, "level": 3}
				],
				"enemies": [
					{"type": "basic_enemy", "count": 3, "hp": 150, "debuffs": [{"type": "bleed", "stacks": 1}], "positions": [{"x": 0, "y": 0}, {"x": 1, "y": 1}, {"x": -1, "y": 1}]},
					{"type": "basic_enemy", "count": 2, "hp": 150, "debuffs": [{"type": "bleed", "stacks": 5}], "positions": [{"x": 0, "y": 2}, {"x": 1, "y": 0}]}
				],
				"scheduled_actions": [
					{"time": 2.0, "type": "record_damage", "unit_id": "vampire_bat", "label": "bleed_1"},
					{"time": 5.0, "type": "record_damage", "unit_id": "vampire_bat", "label": "bleed_5"}
				],
				"expected_behavior": "根据敌人流血层数增加伤害，每层流血增加一定比例伤害"
			}
		"test_vampire_bat_lifesteal_cap":
			return {
				"id": "test_vampire_bat_lifesteal_cap",
				"core_type": "bat_totem",
				"duration": 10.0,
				"units": [
					{"id": "vampire_bat", "x": 0, "y": 1, "level": 3, "hp": 10, "max_hp": 450}
				],
				"enemies": [
					{"type": "basic_enemy", "count": 5, "hp": 100, "positions": [{"x": 0, "y": 0}, {"x": 1, "y": 0}]}
				],
				"scheduled_actions": [
					{"time": 2.0, "type": "record_lifesteal", "unit_id": "vampire_bat", "label": "capped_lifesteal"}
				],
				"expected_behavior": "吸血总量不超过造成伤害的一定比例"
			}
		# ========== 蝴蝶图腾流派单位测试 (6个单位) ==========
		"test_butterfly_totem_torch":
			return {
				"id": "test_butterfly_totem_torch",
				"core_type": "butterfly_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [
					{"id": "torch", "x": 0, "y": 1},
					{"id": "squirrel", "x": 0, "y": 0}
				]
			}
		"test_butterfly_totem_butterfly":
			return {
				"id": "test_butterfly_totem_butterfly",
				"core_type": "butterfly_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "butterfly", "x": 0, "y": 1}]
			}
		"test_butterfly_totem_fairy_dragon":
			return {
				"id": "test_butterfly_totem_fairy_dragon",
				"core_type": "butterfly_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "fairy_dragon", "x": 0, "y": 1}]
			}
		"test_butterfly_totem_phoenix":
			return {
				"id": "test_butterfly_totem_phoenix",
				"core_type": "butterfly_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "phoenix", "x": 0, "y": 1}]
			}
		"test_butterfly_totem_eel":
			return {
				"id": "test_butterfly_totem_eel",
				"core_type": "butterfly_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "eel", "x": 0, "y": 1}]
			}
		"test_butterfly_totem_dragon":
			return {
				"id": "test_butterfly_totem_dragon",
				"core_type": "butterfly_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "dragon", "x": 0, "y": 1}]
			}
		# ========== 狼图腾流派单位测试 (3个单位) ==========
		"test_wolf_devour_system":
			return {
				"id": "test_wolf_devour_system",
				"core_type": "wolf_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [
					{"id": "wolf", "x": 0, "y": 0},
					{"id": "tiger", "x": 0, "y": 1}
				],
				"description": "测试狼的吞噬继承系统"
			}
		"test_wolf_totem_tiger":
			return {
				"id": "test_wolf_totem_tiger",
				"core_type": "wolf_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "tiger", "x": 0, "y": 1}]
			}
		"test_wolf_totem_dog":
			return {
				"id": "test_wolf_totem_dog",
				"core_type": "wolf_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "dog", "x": 0, "y": 1}]
			}
		"test_wolf_totem_lion":
			return {
				"id": "test_wolf_totem_lion",
				"core_type": "wolf_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "lion", "x": 0, "y": 1}]
			}
		# ========== 眼镜蛇图腾流派单位测试 (7个单位) ==========
		"test_viper_totem_spider":
			return {
				"id": "test_viper_totem_spider",
				"core_type": "viper_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "spider", "x": 0, "y": 1}]
			}
		"test_viper_totem_snowman":
			return {
				"id": "test_viper_totem_snowman",
				"core_type": "viper_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "snowman", "x": 0, "y": 1}]
			}
		"test_viper_totem_scorpion":
			return {
				"id": "test_viper_totem_scorpion",
				"core_type": "viper_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "scorpion", "x": 0, "y": 1}]
			}
		"test_viper_totem_viper":
			return {
				"id": "test_viper_totem_viper",
				"core_type": "viper_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "viper", "x": 0, "y": 1}]
			}
		"test_viper_totem_arrow_frog":
			return {
				"id": "test_viper_totem_arrow_frog",
				"core_type": "viper_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "arrow_frog", "x": 0, "y": 1}]
			}
		"test_viper_totem_medusa":
			return {
				"id": "test_viper_totem_medusa",
				"core_type": "viper_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "medusa", "x": 0, "y": 1}]
			}
		"test_viper_totem_lure_snake":
			return {
				"id": "test_viper_totem_lure_snake",
				"core_type": "viper_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "lure_snake", "x": 0, "y": 1}]
			}
		# ========== 鹰图腾流派单位测试 (12个单位) ==========
		"test_eagle_totem_harpy_eagle":
			return {
				"id": "test_eagle_totem_harpy_eagle",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "harpy_eagle", "x": 0, "y": 1}]
			}
		"test_eagle_totem_gale_eagle":
			return {
				"id": "test_eagle_totem_gale_eagle",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "gale_eagle", "x": 0, "y": 1}]
			}
		"test_eagle_totem_kestrel":
			return {
				"id": "test_eagle_totem_kestrel",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "kestrel", "x": 0, "y": 1}]
			}
		"test_eagle_totem_owl":
			return {
				"id": "test_eagle_totem_owl",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "owl", "x": 0, "y": 1}]
			}
		"test_eagle_totem_eagle":
			return {
				"id": "test_eagle_totem_eagle",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "eagle", "x": 0, "y": 1}]
			}
		"test_eagle_totem_vulture":
			return {
				"id": "test_eagle_totem_vulture",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "vulture", "x": 0, "y": 1}]
			}
		"test_eagle_totem_magpie":
			return {
				"id": "test_eagle_totem_magpie",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "magpie", "x": 0, "y": 1}]
			}
		"test_eagle_totem_pigeon":
			return {
				"id": "test_eagle_totem_pigeon",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "pigeon", "x": 0, "y": 1}]
			}
		"test_eagle_totem_woodpecker":
			return {
				"id": "test_eagle_totem_woodpecker",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "woodpecker", "x": 0, "y": 1}]
			}
		"test_eagle_totem_parrot":
			return {
				"id": "test_eagle_totem_parrot",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "parrot", "x": 0, "y": 1}]
			}
		"test_eagle_totem_peacock":
			return {
				"id": "test_eagle_totem_peacock",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "peacock", "x": 0, "y": 1}]
			}
		"test_eagle_totem_storm_eagle":
			return {
				"id": "test_eagle_totem_storm_eagle",
				"core_type": "eagle_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "storm_eagle", "x": 0, "y": 1}]
			}
		# ========== 流血和吸血系统测试 ==========
		"test_bleed_lifesteal_system":
			return {
				"id": "test_bleed_lifesteal_system",
				"core_type": "bat_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 20.0,
				"units": [
					{"id": "mosquito", "x": 0, "y": 1},
					{"id": "blood_mage", "x": 1, "y": 1}
				]
			}
		"test_charm_system":
			return {
				"id": "test_charm_system",
				"core_type": "wolf_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 25.0,
				"units": [
					{"id": "fox", "x": 0, "y": 0},
					{"id": "yak_guardian", "x": 0, "y": 1}
				],
				"description": "测试狐狸魅惑系统（需要等待敌人攻击触发魅惑）"
			}
		"test_medusa_petrify":
			return {
				"id": "test_medusa_petrify",
				"core_type": "viper_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 30.0,
				"units": [
					{"id": "medusa", "x": 0, "y": 0}
				],
				"description": "测试美杜莎石化凝视和石块生成（需要等待石化触发）"
			}
		"test_medusa_petrify_juice":
			return {
				"id": "test_medusa_petrify_juice",
				"core_type": "viper_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 30.0,
				"units": [
					{"id": "medusa", "x": 0, "y": 0}
				],
				"description": "测试美杜莎石化Juice效果：动画冻结、碎裂图像、石块伤害"
			}
	return {}

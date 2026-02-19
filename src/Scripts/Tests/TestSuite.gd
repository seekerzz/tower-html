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
		"test_butterfly_ice":
			return {
				"id": "test_butterfly_ice",
				"core_type": "butterfly_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "ice_butterfly", "x": 0, "y": 1}]
			}
		"test_butterfly_firefly":
			return {
				"id": "test_butterfly_firefly",
				"core_type": "butterfly_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "firefly", "x": 0, "y": 1}]
			}
		"test_butterfly_sprite":
			return {
				"id": "test_butterfly_sprite",
				"core_type": "butterfly_totem",
				"initial_gold": 1000,
				"start_wave_index": 1,
				"duration": 15.0,
				"units": [{"id": "forest_sprite", "x": 0, "y": 1}, {"id": "squirrel", "x": 0, "y": 2}]
			}
	return {}

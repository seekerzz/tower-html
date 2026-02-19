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
	return {}

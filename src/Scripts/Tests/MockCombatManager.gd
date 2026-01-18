extends Node

var spawn_count = 0
var last_stats = {}

func spawn_projectile(start_pos, target_node, dmg, speed, type, stats):
	spawn_count += 1
	last_stats = stats
	print("Mock Spawn: target=", target_node, " dmg=", dmg, " type=", type, " stats=", stats)

func check_kill_bonuses(killer):
	pass

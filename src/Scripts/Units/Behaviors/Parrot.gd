extends "res://src/Scripts/Units/UnitBehavior.gd"

var ammo_queue: Array = []
var max_ammo: int = 0
var is_discharging: bool = false
var range_val: float = 0.0

func on_setup():
	_update_stats()
	update_parrot_range()

func _update_stats():
	var stats = {}
	if unit.unit_data.has("levels") and unit.unit_data["levels"].has(str(unit.level)):
		stats = unit.unit_data["levels"][str(unit.level)]

	if stats.has("mechanics") and stats["mechanics"].has("max_ammo"):
		max_ammo = stats["mechanics"]["max_ammo"]
	else:
		max_ammo = 5

func update_parrot_range():
	if !GameManager.grid_manager: return

	# Accessing _get_neighbor_units from Unit.gd.
	# Assuming we will make it public or it is accessible.
	var neighbors = unit.call("_get_neighbor_units")
	var min_range = 9999.0
	var has_ranged_neighbor = false

	for u in neighbors:
		if u.unit_data.get("attackType") == "ranged":
			has_ranged_neighbor = true
			if u.range_val < min_range:
				min_range = u.range_val

	if has_ranged_neighbor:
		unit.range_val = min_range
	else:
		unit.range_val = 0.0

func capture_bullet(bullet_snapshot: Dictionary):
	if is_discharging: return
	if ammo_queue.size() >= max_ammo: return

	ammo_queue.append(bullet_snapshot.duplicate(true))

	if unit.visual_holder:
		var tween = unit.create_tween()
		tween.tween_property(unit.visual_holder, "scale", Vector2(1.1, 1.1), 0.1)
		tween.tween_property(unit.visual_holder, "scale", Vector2(1.0, 1.0), 0.1)

func on_combat_tick(delta: float) -> bool:
	# Delegate back to private method logic, but implemented here
	var combat_manager = GameManager.combat_manager
	if !combat_manager: return false

	# Parrot finds its own target usually to check range
	var target = combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)
	_do_mimic_attack(target, combat_manager)

	return true # Parrot handles its own attack

func _do_mimic_attack(target, combat_manager):
	if !is_discharging:
		if ammo_queue.size() >= max_ammo:
			if target:
				is_discharging = true

	if is_discharging:
		if ammo_queue.size() > 0:
			var aim_target = target
			if !aim_target or !is_instance_valid(aim_target):
				aim_target = combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)

			if aim_target:
				if unit.attack_cost_mana > 0: GameManager.consume_resource("mana", unit.attack_cost_mana)
				unit.cooldown = unit.atk_speed

				var bullet_data = ammo_queue.pop_front()
				unit.play_attack_anim("ranged", aim_target.global_position)

				var extra = bullet_data.duplicate()
				extra["mimic_damage"] = bullet_data.get("damage", 10.0)
				extra["proj_override"] = bullet_data.get("type", "pinecone")

				combat_manager.spawn_projectile(unit, unit.global_position, aim_target, extra)
				unit.attack_performed.emit(aim_target)
		else:
			is_discharging = false

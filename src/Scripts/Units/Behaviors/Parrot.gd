extends DefaultBehavior

var ammo_queue: Array = []
var max_ammo: int = 5
var is_discharging: bool = false

func on_setup():
	update_max_ammo()

func update_max_ammo():
	if unit.unit_data.has("levels") and unit.unit_data.levels.has(str(unit.level)):
		var stats = unit.unit_data.levels[str(unit.level)]
		if stats.has("mechanics") and stats.mechanics.has("max_ammo"):
			max_ammo = stats.mechanics.max_ammo
	else:
		max_ammo = 5
	unit.update_parrot_range()

func capture_bullet(bullet_snapshot: Dictionary):
	if is_discharging: return
	if ammo_queue.size() >= max_ammo: return
	ammo_queue.append(bullet_snapshot.duplicate(true))

	if unit.visual_holder:
		var tween = unit.create_tween()
		tween.tween_property(unit.visual_holder, "scale", Vector2(1.1, 1.1), 0.1)
		tween.tween_property(unit.visual_holder, "scale", Vector2(1.0, 1.0), 0.1)

func on_combat_tick(delta: float) -> bool:
	if unit.cooldown > 0: return true

	var combat_manager = GameManager.combat_manager
	if !combat_manager: return false

	# Discharge Check
	if !is_discharging:
		if ammo_queue.size() >= max_ammo:
			var target = combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)
			if target:
				is_discharging = true

	if is_discharging:
		if ammo_queue.size() > 0:
			var target = combat_manager.find_nearest_enemy(unit.global_position, unit.range_val)
			if target:
				if unit.attack_cost_mana > 0: GameManager.consume_resource("mana", unit.attack_cost_mana)
				unit.cooldown = unit.atk_speed

				var bullet_data = ammo_queue.pop_front()
				unit.play_attack_anim("ranged", target.global_position)

				var extra = bullet_data.duplicate()
				extra["mimic_damage"] = bullet_data.get("damage", 10.0)
				extra["proj_override"] = bullet_data.get("type", "pinecone")

				combat_manager.spawn_projectile(unit, unit.global_position, target, extra)
				unit.attack_performed.emit(target)
		else:
			is_discharging = false

	return true # Takeover

func update_range_logic():
	# Parrot Range Logic
	if !GameManager.grid_manager: return
	var neighbors = unit._get_neighbor_units()
	var min_range = 9999.0
	var has_ranged_neighbor = false

	for n_unit in neighbors:
		if n_unit.unit_data.get("attackType") == "ranged":
			has_ranged_neighbor = true
			if n_unit.range_val < min_range:
				min_range = n_unit.range_val

	if has_ranged_neighbor:
		unit.range_val = min_range
	else:
		unit.range_val = 0.0

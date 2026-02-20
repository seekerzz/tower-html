extends "res://src/Scripts/Units/Behaviors/DefaultBehavior.gd"

var shield_amount: float = 0.0
var last_combat_time: float = 0.0
var out_of_combat_duration: float = 5.0
var max_shield_percent: float = 0.1

func on_setup():
	if not GameManager.wave_started.is_connected(_on_wave_start):
		GameManager.wave_started.connect(_on_wave_start)
	if not GameManager.core_healed.is_connected(_on_core_healed):
		GameManager.core_healed.connect(_on_core_healed)

	call_deferred("_on_wave_start")

func _on_wave_start():
	shield_amount = 0.0
	last_combat_time = 0.0

	if unit.level >= 2:
		out_of_combat_duration = 4.0
		max_shield_percent = 0.15
	else:
		out_of_combat_duration = 5.0
		max_shield_percent = 0.1

func on_tick(delta: float):
	last_combat_time += delta

	if last_combat_time >= out_of_combat_duration:
		var target_shield = unit.max_hp * max_shield_percent
		# Only generate if we are below target (Lv3 overflow can go higher, don't reduce it)
		if shield_amount < target_shield:
			shield_amount = target_shield
			unit.spawn_buff_effect("🛡️")

func on_damage_taken(amount: float, source: Node) -> float:
	last_combat_time = 0.0

	if shield_amount > 0:
		var shield_absorb = min(shield_amount, amount)
		shield_amount -= shield_absorb
		amount -= shield_absorb

		if shield_amount <= 0:
			unit.spawn_buff_effect("💔")

	return amount

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	last_combat_time = 0.0

	if shield_amount > 0:
		var bonus_damage = shield_amount * 0.5
		if target and is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(bonus_damage, unit, "physical")

func _on_core_healed(amount: float, overheal: float):
	if unit.level >= 3:
		if overheal > 0:
			shield_amount += overheal * 0.1
			unit.spawn_buff_effect("➕🛡️")

func on_cleanup():
	if GameManager.wave_started.is_connected(_on_wave_start):
		GameManager.wave_started.disconnect(_on_wave_start)
	if GameManager.core_healed.is_connected(_on_core_healed):
		GameManager.core_healed.disconnect(_on_core_healed)

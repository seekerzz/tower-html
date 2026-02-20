extends "res://src/Scripts/Units/Behaviors/DefaultBehavior.gd"

var current_buff_multiplier: float = 1.0

func on_setup():
	current_buff_multiplier = 1.0

func on_stats_updated():
	current_buff_multiplier = 1.0

func on_tick(delta: float):
	# Calculate HP loss percentage
	var hp_percent = GameManager.core_health / GameManager.max_core_health
	var loss_percent = 1.0 - hp_percent

	# Calculate chunks (every 10%)
	# Use slight epsilon to handle float precision if needed
	var chunks = floor((loss_percent + 0.0001) / 0.1)

	# Determine bonus per chunk
	var bonus_per_chunk = 0.05
	if unit.level >= 2:
		bonus_per_chunk = 0.10

	# Calculate new multiplier (e.g. 1.0 + 5 * 0.05 = 1.25)
	var new_multiplier = 1.0 + (chunks * bonus_per_chunk)

	# Optimization: Only update if changed
	if abs(new_multiplier - current_buff_multiplier) > 0.001:
		# Remove old multiplier effect (atk_speed is interval, so multiply by old factor to revert)
		# New interval = Base / NewMultiplier
		# Current = Base / OldMultiplier
		# Base = Current * OldMultiplier
		# New = (Current * OldMultiplier) / NewMultiplier

		unit.atk_speed = (unit.atk_speed * current_buff_multiplier) / new_multiplier
		current_buff_multiplier = new_multiplier

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	super.on_projectile_hit(target, damage, projectile)

	# Lv3 Splash Logic
	if unit.level >= 3:
		# Condition: Attack speed +80% (multiplier >= 1.8)
		# Note: 8 chunks * 0.10 = 0.80. So at 20% HP left (80% loss), bonus is +80%.
		if current_buff_multiplier >= 1.8 - 0.001:
			_trigger_splash(target, damage)

func _trigger_splash(target: Node2D, damage: float):
	if !GameManager.combat_manager: return

	# Range: 100.0 radius (approx 1.5 tiles)
	var splash_radius = 100.0
	var enemies = GameManager.combat_manager.get_enemies_in_range(target.global_position, splash_radius)

	for enemy in enemies:
		if enemy != target and is_instance_valid(enemy):
			# 50% splash damage
			enemy.take_damage(damage * 0.5, unit)

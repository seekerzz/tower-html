extends "res://src/Scripts/Effects/StatusEffect.gd"

var base_damage: float = 0.0
var explosion_damage: float = 0.0
var tick_timer: float = 0.0
const TICK_INTERVAL = 0.5 # Damage every 0.5s or 1.0s? Requirement says "per second".

func setup(target: Node, source: Node, params: Dictionary):
	super.setup(target, source, params)
	type_key = "burn"
	base_damage = params.get("damage", 10.0)
	explosion_damage = params.get("explosion_damage", base_damage * 3.0)

func apply(delta: float):
	super.apply(delta)

	tick_timer += delta
	if tick_timer >= 1.0:
		tick_timer -= 1.0
		_deal_damage()

func stack(params: Dictionary):
	super.stack(params)
	# Stacks increase automatically in base class if params has 'stacks', but here we might want specific logic.
	# Requirement: "stacks += 1".
	# If base class stack() adds params.stacks, we just ensure params has stacks=1.
	pass

func _deal_damage():
	var host = get_parent()
	if host and host.has_method("take_damage"):
		var dmg = base_damage * stacks
		host.take_damage(dmg, source_unit, "fire")

func _on_host_died():
	# Explosion logic
	var host = get_parent()
	if not host: return

	var center = host.global_position
	var radius = 120.0
	var final_explosion_damage = explosion_damage * stacks

	# Visual
	var effect = load("res://src/Scripts/Effects/SlashEffect.gd").new()
	host.get_parent().call_deferred("add_child", effect)
	effect.global_position = center
	effect.configure("cross", Color.ORANGE)
	effect.scale = Vector2(3, 3)
	effect.play()

	# Damage Area
	# Use call_deferred to avoid issues during physics step or iteration
	call_deferred("_perform_explosion", center, radius, final_explosion_damage)

func _perform_explosion(center, radius, damage):
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = center.distance_to(enemy.global_position)
			if dist <= radius:
				enemy.take_damage(damage, source_unit, "fire")
				# Chain reaction: Apply burn to hit enemies?
				# Existing logic: "enemy.effects["burn"] = 5.0"
				# So yes, we should apply burn to them too.
				if enemy.has_method("apply_status"):
					var burn_script = load("res://src/Scripts/Effects/BurnEffect.gd")
					enemy.apply_status(burn_script, {
						"duration": 5.0,
						"damage": base_damage, # Propagate base damage? Or fixed? Existing logic used source.damage if available or fixed.
						"stacks": 1
					})

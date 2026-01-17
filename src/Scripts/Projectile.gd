extends "res://src/Scripts/Projectiles/BaseProjectile.gd"

# Logic for specific projectile types
var target = null # Enemy node
var life: float = 2.0
var type: String = "pinecone"
var hit_list = []
var shared_hit_list_ref: Array = []

var is_meteor_falling: bool = false
var meteor_target: Vector2 = Vector2.ZERO

# Storage for all stats
var stats: Dictionary = {}

# Advanced Stats
var pierce: int = 0
var bounce: int = 0
var split: int = 0
var chain: int = 0
var damage_type: String = "physical"
var is_critical: bool = false
var freeze_duration: float = 0.0

# Visuals
var visual_node: Node2D = null
var is_fading: bool = false

# Dragon Breath State
enum State { MOVING, HOVERING, STUCK, RETURNING }
var state = State.MOVING
var dragon_breath_timer: float = 0.0

# Feather State
var feather_original_target_pos: Vector2 = Vector2.ZERO
var feather_stuck_pos: Vector2 = Vector2.ZERO

const PROJECTILE_SCENE = preload("res://src/Scenes/Game/Projectile.tscn")
const PROJECTILE_VISUALS_SCRIPT = preload("res://src/Scripts/Projectiles/ProjectileVisuals.gd")

func _ready():
	super._ready() # Connect signals

	# Instantiate Visuals Controller
	var visuals = PROJECTILE_VISUALS_SCRIPT.new()
	visuals.name = "ProjectileVisuals"
	add_child(visuals)
	visual_node = visuals

	# Initialize visuals if setup was already called
	if type != "":
		visual_node.update_visuals(type, stats)
		_update_collision_shape()

	# Hide legacy nodes if they exist in the scene (ColorRect)
	if has_node("ColorRect"): get_node("ColorRect").hide()
	if has_node("Sprite2D"): get_node("Sprite2D").hide()
	if has_node("Polygon2D"): get_node("Polygon2D").hide()

func setup(start_pos, target_node, dmg, proj_speed, proj_type, incoming_stats = {}):
	position = start_pos
	target = target_node
	damage = dmg
	speed = proj_speed
	type = proj_type
	# Explicitly assign to the member variable `stats`.
	# Note: incoming_stats is passed by reference if it's a Dictionary.
	# To prevent modification of the original dictionary if used elsewhere, duplication is safer but overhead.
	# For now, assignment is correct for referencing.
	stats = incoming_stats

	if stats.has("source"):
		source_unit = stats.source

	# Map stats to payload_effects
	payload_effects.clear()

	var effects_dict = stats.get("effects", {})
	if effects_dict.get("burn", 0.0) > 0.0:
		payload_effects.append({
			"script": load("res://src/Scripts/Effects/BurnEffect.gd"),
			"params": {
				"duration": effects_dict["burn"],
				"damage": damage, # Default burn damage uses projectile damage or source damage?
				# Original Logic: "target_node.effects["burn"] = max(..., effects["burn"])" -> Only duration was passed.
				# "if "burn_source" in target_node: target_node.burn_source = source_unit"
				# Burn Effect logic uses params["damage"]. If not set, defaults to 10.
				# Let's pass 'damage' from stats or projectile damage.
				# Usually burn damage is derived from source.damage but here we can pass it.
				"source": source_unit
			}
		})
	if effects_dict.get("poison", 0.0) > 0.0:
		payload_effects.append({
			"script": load("res://src/Scripts/Effects/PoisonEffect.gd"),
			"params": {
				"duration": effects_dict["poison"],
				"damage": damage * 0.5, # Poison usually weaker per tick but stacks? Logic was: "damage_increment = base_dmg * 0.1 * stacks".
				# PoisonEffect uses base_damage.
				# Let's pass a reasonable base damage. Source unit damage is better.
				"source": source_unit,
				"stacks": 1
			}
		})
	if effects_dict.get("slow", 0.0) > 0.0:
		payload_effects.append({
			"script": load("res://src/Scripts/Effects/SlowEffect.gd"),
			"params": {
				"duration": effects_dict["slow"],
				"slow_factor": 0.5, # Default 50% slow
				"source": source_unit
			}
		})

	# Freeze
	if effects_dict.get("freeze", 0.0) > 0.0:
		freeze_duration = effects_dict["freeze"]

	pierce = stats.get("pierce", 0)
	bounce = stats.get("bounce", 0)
	split = stats.get("split", 0)
	chain = stats.get("chain", 0)
	damage_type = stats.get("damageType", "physical")
	is_critical = stats.get("is_critical", false)

	if stats.has("life"):
		life = stats.get("life")

	if stats.has("shared_hit_list"):
		shared_hit_list_ref = stats.get("shared_hit_list")

	if stats.has("is_meteor"):
		is_meteor_falling = true
		meteor_target = stats["ground_pos"]
		type = "fireball" # Logic from original
		if proj_type == "fireball": pass
		else: type = "dragon_breath"

		if type == "fireball":
			type = "dragon_breath"

		speed = 1200.0
		rotation = (meteor_target - position).angle()

	# Initial rotation
	if not is_meteor_falling:
		if target and is_instance_valid(target):
			look_at(target.global_position)
		elif stats.has("target_pos"):
			look_at(stats.target_pos)

		if type == "feather":
			if target and is_instance_valid(target):
				feather_original_target_pos = target.global_position
			elif stats.has("target_pos"):
				feather_original_target_pos = stats.target_pos
			else:
				var r = stats.get("range", 1000.0)
				feather_original_target_pos = position + Vector2.RIGHT.rotated(rotation) * r

		if stats.get("angle") != null:
			rotation = stats.get("angle")

	# Logic for Black Hole
	if type == "black_hole_field":
		speed = 0.0
		if stats.has("duration"):
			life = stats["duration"]

	# Critical Visuals handled in visual node?
	if is_critical:
		scale *= 1.2

	# Update Visuals
	# If setup is called before _ready (which is typical for manual instantiation), visual_node is null.
	# We rely on _ready calling update_visuals later.
	if visual_node:
		visual_node.update_visuals(type, stats)
		_update_collision_shape()

func _update_collision_shape():
	if type == "feather":
		# Adjust collision for feather
		var col_shape = get_node_or_null("CollisionShape2D")
		if col_shape:
			var new_shape = CircleShape2D.new()
			new_shape.radius = 12.0
			col_shape.shape = new_shape

func fade_out():
	if is_fading: return
	if state == State.STUCK: return

	is_fading = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)

	if type != "swarm_wave" and type != "roar":
		tween.tween_property(self, "scale", scale * 1.5, 0.2)

	tween.chain().tween_callback(queue_free)

func _process(delta):
	# Override BaseProjectile movement

	if is_fading: return

	if is_meteor_falling:
		if is_instance_valid(target):
			meteor_target = target.global_position
			rotation = (meteor_target - global_position).angle()

		var dist = global_position.distance_to(meteor_target)
		if dist < 20.0:
			_on_meteor_hit()
			return

		position += Vector2.RIGHT.rotated(rotation) * speed * delta
		return

	if type == "dragon_breath":
		_process_dragon_breath(delta)
		return

	if type == "feather":
		_process_feather(delta)
		if state != State.RETURNING:
			return

		if state == State.RETURNING and source_unit and is_instance_valid(source_unit):
			if global_position.distance_to(source_unit.global_position) < 15.0:
				queue_free()
				return

	if type == "black_hole_field":
		_process_black_hole(delta)

	life -= delta
	if life <= 0:
		fade_out()
		return

	if type == "roar":
		scale += Vector2(delta, delta) * speed * 0.01
		modulate.a = max(0, modulate.a - delta * 0.8)
		# Note: Roar visual in VisualsNode doesn't update width automatically unless we expose it.
		# But we can accept simple scaling for now.

	var direction = Vector2.RIGHT.rotated(rotation)

	if is_instance_valid(target):
		var target_dir = (target.global_position - global_position).normalized()
		direction = target_dir
		rotation = direction.angle()

	position += direction * speed * delta

	# Enemy Ranged Attack
	if !is_instance_valid(target) and stats.has("target_pos") and source_unit and source_unit.is_in_group("enemies"):
		if global_position.distance_to(stats.target_pos) < 15.0:
			GameManager.damage_core(damage)
			_spawn_hit_visual(global_position)
			queue_free()
			return

	if visual_node:
		visual_node.rotation += delta * 15.0

func _process_black_hole(delta):
	var pull_radius = stats.get("skillRadius", 150.0)
	var pull_strength = stats.get("skillStrength", 3000.0)
	var black_hole_center = global_position

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var dist = black_hole_center.distance_to(enemy.global_position)
		if dist < pull_radius:
			var dir = (black_hole_center - enemy.global_position).normalized()
			var mass = 1.0
			if "mass" in enemy: mass = enemy.mass
			elif "knockback_resistance" in enemy: mass = max(enemy.knockback_resistance, 1.0)
			mass = max(mass, 0.1)

			var force_magnitude = (pull_strength / max(dist, 10.0)) * (1.0 / mass)
			var force_vector = dir * force_magnitude * delta

			if enemy.has_method("apply_force"):
				enemy.apply_force(force_vector)
			else:
				enemy.global_position += force_vector

func _process_dragon_breath(delta):
	if state == State.MOVING:
		life -= delta
		if life <= 0:
			fade_out()
			return

		if is_instance_valid(target):
			var dist = global_position.distance_to(target.global_position)
			var dir = (target.global_position - global_position).normalized()
			position += dir * speed * delta

			if dist < 10.0:
				state = State.HOVERING
				dragon_breath_timer = 3.0
		else:
			state = State.HOVERING
			dragon_breath_timer = 2.0

	elif state == State.HOVERING:
		dragon_breath_timer -= delta
		if dragon_breath_timer <= 0:
			fade_out()
			return

		var pull_radius = 150.0
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < pull_radius:
				var pull_dir = (global_position - enemy.global_position).normalized()
				enemy.global_position += pull_dir * 100.0 * delta
				enemy.take_damage(damage * delta, source_unit, damage_type)

# Overriding BaseProjectile _handle_hit
func _handle_hit(target_node):
	if is_fading: return
	if type == "dragon_breath": return
	if type == "black_hole_field": return
	if type == "feather" and state == State.STUCK: return

	if target_node.is_in_group("enemies"):
		if source_unit and source_unit.is_in_group("enemies"):
			return

		if shared_hit_list_ref != null and target_node in shared_hit_list_ref: return
		if target_node in hit_list: return

		# Feather Pull
		if type == "feather" and state == State.RETURNING:
			var pull_str = 0.0
			if source_unit and "unit_data" in source_unit and source_unit.unit_data.has("levels"):
				var lvl_stats = source_unit.unit_data["levels"][str(source_unit.level)]
				if lvl_stats.has("mechanics"):
					pull_str = lvl_stats["mechanics"].get("pull_strength", 0.0)

			if pull_str > 0:
				var dir = (source_unit.global_position - target_node.global_position).normalized()
				target_node.global_position += dir * (pull_str * 0.05)

		# Damage
		var final_damage_type = damage_type
		if is_critical:
			final_damage_type = "crit"

		var kb_force = damage * speed * 0.005
		if type == "roar": kb_force *= 2.0
		if type == "snowball": kb_force *= 1.5

		if target_node.has_method("take_damage"):
			target_node.take_damage(damage, source_unit, final_damage_type, self, kb_force)

		# Apply Status Effects (BaseProjectile method)
		apply_payload(target_node)

		# Freeze Logic
		if freeze_duration > 0.0:
			if target_node.has_method("apply_freeze"):
				target_node.apply_freeze(freeze_duration)
			elif "freeze_timer" in target_node:
				target_node.freeze_timer = max(target_node.freeze_timer, freeze_duration)

		# Trigger Source Behavior
		if source_unit and is_instance_valid(source_unit) and "behavior" in source_unit and source_unit.behavior:
			if source_unit.behavior.has_method("on_projectile_hit"):
				source_unit.behavior.on_projectile_hit(target_node, damage, self)

		hit_list.append(target_node)
		if shared_hit_list_ref != null:
			shared_hit_list_ref.append(target_node)

		# Bounce/Chain
		var total_bounce = bounce + chain
		var bounced = false

		if bounce > 0:
			bounced = perform_physical_bounce(target_node)
		elif chain > 0:
			bounced = perform_bounce(target_node)

		# Pierce & Split
		if not bounced:
			if type == "roar":
				pass
			elif pierce > 0:
				pierce -= 1
			else:
				if split > 0 and type != "roar":
					perform_split()

				_spawn_hit_visual(target_node.global_position)
				if type != "feather":
					queue_free()

func _process_feather(delta):
	if (state == State.STUCK or state == State.RETURNING or state == State.MOVING) and (!source_unit or !is_instance_valid(source_unit)):
		queue_free()
		return

	if state == State.MOVING:
		position += Vector2.RIGHT.rotated(rotation) * speed * delta
		if source_unit and is_instance_valid(source_unit):
			var start_pos = source_unit.global_position
			var to_target = feather_original_target_pos - start_pos
			var to_current = global_position - start_pos
			var projected_dist = to_current.dot(to_target.normalized())
			var target_dist = to_target.length()

			if projected_dist >= target_dist + 40.0:
				_become_stuck()
		else:
			if global_position.distance_to(feather_original_target_pos) < 10.0:
				_become_stuck()

func _become_stuck():
	feather_stuck_pos = position
	state = State.STUCK
	set_deferred("monitoring", false)

	if visual_node:
		var tween = create_tween()
		var base_rot = rotation
		tween.tween_property(visual_node, "rotation", base_rot + 0.2, 0.05)
		tween.tween_property(visual_node, "rotation", base_rot - 0.2, 0.05)
		tween.tween_property(visual_node, "rotation", base_rot, 0.05)

	var dust = Polygon2D.new()
	dust.polygon = PackedVector2Array([Vector2(-2,-2), Vector2(2,-2), Vector2(2,2), Vector2(-2,2)])
	dust.color = Color(0.6, 0.6, 0.6, 0.5)
	dust.position = Vector2.ZERO
	add_child(dust)
	var t = create_tween()
	t.tween_property(dust, "scale", Vector2(2,2), 0.3)
	t.parallel().tween_property(dust, "modulate:a", 0.0, 0.3)
	t.tween_callback(dust.queue_free)

func recall():
	if state != State.STUCK and state != State.MOVING: return
	state = State.RETURNING
	target = source_unit
	pierce = 999
	hit_list.clear()
	shared_hit_list_ref = []
	monitoring = true

	var bodies = get_overlapping_bodies()
	for body in bodies: _handle_hit(body)
	var areas = get_overlapping_areas()
	for area in areas: _handle_hit(area)

	if visual_node:
		visual_node.modulate = Color.RED

func _spawn_hit_visual(pos: Vector2):
	var effect = load("res://src/Scripts/Effects/SlashEffect.gd").new()
	get_parent().add_child(effect)
	effect.global_position = pos
	effect.rotation = randf() * TAU

	var shape = "slash"
	var col = Color.WHITE
	if type == "pinecone":
		shape = "circle"; col = Color("8B4513")
	elif type == "ink":
		shape = "blob"; col = Color.BLACK
	elif type == "stinger":
		shape = "triangle"; col = Color.YELLOW
	elif type == "pollen":
		shape = "star"; col = Color.PINK

	effect.configure(shape, col)
	effect.play()

func _on_meteor_hit():
	is_meteor_falling = false
	var bounce_angle = rotation + randf_range(-0.5, 0.5)
	rotation = bounce_angle
	life = 0.3
	speed = 50.0
	target = null

	var SlashEffectScript = load("res://src/Scripts/Effects/SlashEffect.gd")
	if SlashEffectScript:
		var slash = SlashEffectScript.new()
		get_parent().add_child(slash)
		slash.global_position = global_position
		slash.rotation = rotation
		slash.modulate = Color.ORANGE
		slash.play()

	type = "meteor_debris"

func perform_split():
	var angles = [rotation + 0.5, rotation - 0.5]
	for angle in angles:
		var proj = PROJECTILE_SCENE.instantiate()
		var new_stats = {
			"pierce": 0, "bounce": 0, "split": 0, "chain": 0,
			"angle": angle, "source": source_unit, "damageType": damage_type
		}
		proj.setup(global_position, null, damage * 0.5, speed, type, new_stats)
		get_parent().call_deferred("add_child", proj)

func perform_bounce(current_hit_enemy):
	var search_range = 300.0
	var nearest = null
	var min_dist = search_range
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy == current_hit_enemy or enemy in hit_list: continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = enemy
	if nearest:
		target = nearest
		damage *= 0.8
		if chain > 0: chain -= 1
		life = 1.0
		return true
	return false

func perform_physical_bounce(hit_node):
	var incident = Vector2.RIGHT.rotated(rotation)
	var normal = Vector2.ZERO
	if "enemy_data" in hit_node:
		var e_data = hit_node.enemy_data
		if e_data.get("shape") == "rect" or hit_node.type_key == "crab":
			var local_hit = hit_node.to_local(global_position)
			var size_grid = e_data.get("size_grid", [1,1])
			var w = size_grid[0] * 60
			var h = size_grid[1] * 60
			var aspect = w / h if h > 0 else 1.0
			if abs(local_hit.x) > abs(local_hit.y) * aspect:
				normal = Vector2(sign(local_hit.x), 0).rotated(hit_node.rotation)
			else:
				normal = Vector2(0, sign(local_hit.y)).rotated(hit_node.rotation)
		else:
			if hit_node.velocity.length() > 0.1: normal = hit_node.velocity.normalized()
			else: normal = (global_position - hit_node.global_position).normalized()
	else:
		normal = (global_position - hit_node.global_position).normalized()

	var dot = incident.dot(normal)
	var reflect = incident - 2 * dot * normal
	rotation = reflect.angle()
	target = null
	damage *= 0.8
	bounce -= 1
	life = 1.0
	return true

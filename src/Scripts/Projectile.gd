extends Node2D

var target = null # Enemy node
var speed: float = 400.0
var damage: float = 10.0
var life: float = 2.0
var type: String = "dot"
var hit_list = []
var source_unit = null

# Advanced Stats
var pierce: int = 0
var bounce: int = 0
var split: int = 0
var chain: int = 0

# Visuals
var visual_node: Node2D = null

# Blackhole State
enum State { MOVING, HOVERING }
var state = State.MOVING
var blackhole_timer: float = 0.0

const PROJECTILE_SCENE = preload("res://src/Scenes/Game/Projectile.tscn")

func setup(start_pos, target_node, dmg, proj_speed, proj_type, stats = {}):
	position = start_pos
	target = target_node
	damage = dmg
	speed = proj_speed
	type = proj_type

	if stats.has("source"):
		source_unit = stats.source

	pierce = stats.get("pierce", 0)
	bounce = stats.get("bounce", 0)
	split = stats.get("split", 0)
	chain = stats.get("chain", 0)

	# Initial rotation
	if target and is_instance_valid(target):
		look_at(target.global_position)
	elif stats.get("angle") != null:
		rotation = stats.get("angle")

	# Visual Separation
	if has_node("Sprite2D"):
		visual_node = get_node("Sprite2D")
	elif has_node("Polygon2D"):
		visual_node = get_node("Polygon2D")

func _process(delta):
	# Blackhole Logic
	if type == "blackhole":
		_process_blackhole(delta)
		return # Blackhole handles its own life/movement

	life -= delta
	if life <= 0:
		queue_free()
		return

	# Swarm Logic
	if type == "swarm_wave":
		scale += Vector2(delta, delta) * 2.0 # Growth rate
		modulate.a = max(0, modulate.a - delta * 0.5)

	var direction = Vector2.RIGHT.rotated(rotation)

	if is_instance_valid(target):
		var target_dir = (target.global_position - global_position).normalized()
		direction = target_dir
		rotation = direction.angle() # Turn entire node to face target

	position += direction * speed * delta

	# Visual Rotation (Spin)
	if visual_node:
		visual_node.rotation += delta * 15.0

func _process_blackhole(delta):
	if state == State.MOVING:
		life -= delta # Safety
		if life <= 0: queue_free(); return

		if is_instance_valid(target):
			var dist = global_position.distance_to(target.global_position)
			var dir = (target.global_position - global_position).normalized()
			position += dir * speed * delta

			if dist < 10.0:
				state = State.HOVERING
				blackhole_timer = 3.0 # Duration
		else:
			# Lost target, move straight or just stop
			state = State.HOVERING
			blackhole_timer = 2.0

	elif state == State.HOVERING:
		blackhole_timer -= delta
		if blackhole_timer <= 0:
			queue_free()
			return

		# Pull enemies
		var pull_radius = 150.0
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < pull_radius:
				var pull_dir = (global_position - enemy.global_position).normalized()
				enemy.global_position += pull_dir * 100.0 * delta # Pull speed
				enemy.take_damage(damage * delta, source_unit) # DoT

func _on_area_2d_area_entered(area):
	if type == "blackhole": return # Blackhole damages in _process

	if area.is_in_group("enemies"):
		if area in hit_list: return

		# Apply Damage
		area.take_damage(damage, source_unit)
		hit_list.append(area)

		# 1. Bounce/Chain Logic
		# Chain is treated essentially as bounce in the reference
		var total_bounce = bounce + chain
		var bounced = false

		if total_bounce > 0:
			bounced = perform_bounce(area)

		# 2. Pierce & Split Logic
		# If we bounced, the original "energy" went into the bounce (conceptually),
		# so we don't pierce on the original line. The projectile effectively moved.
		# If we didn't bounce, we check pierce.
		if not bounced:
			if pierce > 0:
				pierce -= 1
			else:
				# Destroying - check for split
				if split > 0:
					perform_split()
				queue_free()

func perform_split():
	# Spawn 2 projectiles at +/- 0.5 radians (~28 degrees)
	var angles = [rotation + 0.5, rotation - 0.5]

	for angle in angles:
		var proj = PROJECTILE_SCENE.instantiate()
		var new_stats = {
			"pierce": 0,
			"bounce": 0,
			"split": 0,
			"chain": 0,
			"angle": angle,
			"source": source_unit
		}
		# Split projectiles usually don't have a specific target unless we find one,
		# but for now let's just make them fly in the direction.
		proj.setup(global_position, null, damage * 0.5, speed, type, new_stats)
		get_parent().call_deferred("add_child", proj)

func perform_bounce(current_hit_enemy):
	# Find nearest enemy NOT in hit_list within range
	var search_range = 300.0
	var nearest = null
	var min_dist = search_range

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy == current_hit_enemy or enemy in hit_list:
			continue

		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = enemy

	if nearest:
		# Update this projectile to fly towards the new target
		target = nearest
		damage *= 0.8
		if bounce > 0: bounce -= 1
		elif chain > 0: chain -= 1

		# Reset life slightly? Ref sets life to 0.5 or similar for bounces sometimes,
		# or just lets it fly. Let's ensure it has enough life to reach.
		life = 1.0

		return true # Bounced successfully

	return false # No target to bounce to

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

func _process(delta):
	life -= delta
	if life <= 0:
		queue_free()
		return

	var direction = Vector2.RIGHT.rotated(rotation)

	# Homing behavior (only if we have a target and we haven't just bounced/split into a non-homing state)
	# For simplicity, and matching ref somewhat, let's say projectiles home if they have a target.
	# But split projectiles might not have a target.
	if is_instance_valid(target):
		var target_dir = (target.global_position - global_position).normalized()
		# Use a turning speed or instant turn? Ref implies instant tracking or simple move towards target.
		# Godot implementation in read_file was: direction = target_dir; look_at(...)
		direction = target_dir
		look_at(target.global_position)

	position += direction * speed * delta

func _on_area_2d_area_entered(area):
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

extends Node2D

var target = null # Enemy node
var speed: float = 400.0
var damage: float = 10.0
var life: float = 2.0
var type: String = "dot"
var hit_list = []
var source_unit = null
var effects: Dictionary = {}

# Advanced Stats
var pierce: int = 0
var bounce: int = 0
var split: int = 0
var chain: int = 0

# Visuals
var visual_node: Node2D = null
var is_fading: bool = false

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

	if stats.has("effects"):
		effects = stats.effects.duplicate()

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

	# Swarm Wave Visuals
	if type == "swarm_wave":
		_setup_swarm_wave()
	elif type == "black_hole":
		_setup_black_hole()

func fade_out():
	if is_fading: return
	is_fading = true

	# Disable collision to stop interacting
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	# Slight expansion for explosion effect
	tween.tween_property(self, "scale", scale * 1.5, 0.2)
	tween.chain().tween_callback(queue_free)

func _process(delta):
	if is_fading: return

	# Blackhole Logic
	if type == "blackhole" or type == "black_hole":
		_process_blackhole(delta)
		return # Blackhole handles its own life/movement

	life -= delta
	if life <= 0:
		fade_out()
		return

	# Swarm Logic
	if type == "swarm_wave":
		scale += Vector2(delta, delta) * speed * 0.01 # Adjusted growth based on speed
		modulate.a = max(0, modulate.a - delta * 0.8) # Faster fade
		if has_node("WaveLine"):
			var line = get_node("WaveLine")
			line.width += delta * 15.0

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
		if life <= 0:
			fade_out()
			return

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
			fade_out()
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
	if is_fading: return
	if type == "blackhole" or type == "black_hole": return # Blackhole damages in _process

	if area.is_in_group("enemies"):
		if area in hit_list: return

		# Apply Damage
		area.take_damage(damage, source_unit)

		# Apply Status Effects
		if effects.get("burn", 0.0) > 0.0:
			area.effects["burn"] = max(area.effects["burn"], effects["burn"])
		if effects.get("poison", 0.0) > 0.0:
			area.effects["poison"] = max(area.effects["poison"], effects["poison"])

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
			if type == "swarm_wave":
				# Swarm wave has infinite pierce by default
				pass
			elif pierce > 0:
				pierce -= 1
			else:
				# Destroying - check for split
				if split > 0:
					perform_split()
				fade_out()

func _setup_swarm_wave():
	# Hide default visuals if any
	if visual_node: visual_node.hide()
	# Fix: Use get_node_or_null since ColorRect might not exist or be moved in other contexts
	if has_node("ColorRect"):
		get_node("ColorRect").hide()

	var line = Line2D.new()
	line.name = "WaveLine"
	line.width = 3.0
	line.default_color = Color(0.2, 0.8, 0.4, 0.8)

	# Create Arc
	var points_arr = []
	var radius = 20.0
	var segments = 12
	var start_angle = deg_to_rad(-60)
	var end_angle = deg_to_rad(60)

	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = lerp(start_angle, end_angle, t)
		points_arr.append(Vector2(cos(angle), sin(angle)) * radius)

	line.points = PackedVector2Array(points_arr)
	add_child(line)

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

func _setup_black_hole():
	# Step A: Hide default appearance
	if has_node("ColorRect"):
		get_node("ColorRect").hide()
	# Check if VisualHolder/ColorRect exists (unlikely in Projectile.tscn but good practice if structure mimics Unit)
	# Projectile.tscn structure is simpler usually, but let's be safe

	if visual_node:
		visual_node.hide()

	# Step B: Event Horizon (Black solid circle)
	var poly = Polygon2D.new()
	var points = PackedVector2Array()
	var radius = 12.0
	var segments = 32
	for i in range(segments):
		var angle = (i * TAU) / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	poly.polygon = points
	poly.color = Color.BLACK
	add_child(poly)

	# Step C: Accretion Disk (Particle System)
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()

	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	material.emission_ring_inner_radius = 100.0
	material.emission_ring_radius = 120.0
	material.gravity = Vector3.ZERO
	material.radial_accel_min = -150.0
	material.radial_accel_max = -100.0
	material.tangential_accel_min = 60.0
	material.tangential_accel_max = 100.0

	# Gradient: Outer (Purple) to Inner (Black)
	var gradient = Gradient.new()
	# We want 0 (start) to be purple, 1 (end) to be black.
	gradient.set_color(0, Color(0.5, 0.0, 1.0)) # Purple
	gradient.set_color(1, Color.BLACK)

	var grad_tex = GradientTexture1D.new()
	grad_tex.gradient = gradient
	material.color_ramp = grad_tex

	particles.process_material = material
	particles.lifetime = 0.8
	particles.amount = 60

	# Create a 4x4 white placeholder texture
	var img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex = ImageTexture.create_from_image(img)
	particles.texture = tex

	add_child(particles)

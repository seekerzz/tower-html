extends Node2D

var target = null # Enemy node
var speed: float = 400.0
var damage: float = 10.0
var life: float = 2.0
var type: String = "pinecone"
var hit_list = []
var source_unit = null
var effects: Dictionary = {}

# Advanced Stats
var pierce: int = 0
var bounce: int = 0
var split: int = 0
var chain: int = 0
var damage_type: String = "physical"
var is_critical: bool = false

# Visuals
var visual_node: Node2D = null
var is_fading: bool = false

# Dragon Breath State
enum State { MOVING, HOVERING }
var state = State.MOVING
var dragon_breath_timer: float = 0.0

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
	damage_type = stats.get("damageType", "physical")
	is_critical = stats.get("is_critical", false)

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

	if is_critical:
		scale *= 1.2
		# Optionally change color or modulation to indicate crit visually on the projectile itself
		# modulate = Color(1.5, 1.2, 0.5) # Example glow

	# Swarm Wave Visuals
	if type == "snowball":
		_setup_snowball()
	elif type == "web":
		_setup_web()
	# Visual Setup
	elif type == "stinger":
		_setup_stinger()
	elif type == "roar":
		_setup_roar()
	elif type == "dragon_breath":
		_setup_dragon_breath()
	elif type == "pinecone":
		_setup_simple_visual(Color("8B4513"), "circle") # Brown circle
	elif type == "ink":
		_setup_simple_visual(Color.BLACK, "blob")
	elif type == "stinger":
		_setup_simple_visual(Color.YELLOW, "triangle")
	elif type == "pollen":
		_setup_simple_visual(Color.PINK, "star")
	elif type == "lightning":
		# Keep lightning if it was handled elsewhere or add simple visual
		_setup_simple_visual(Color.CYAN, "line")

func fade_out():
	if is_fading: return
	is_fading = true

	# Disable collision to stop interacting
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)

	if type != "swarm_wave" and type != "roar":
		# Slight expansion for explosion effect
		tween.tween_property(self, "scale", scale * 1.5, 0.2)

	tween.chain().tween_callback(queue_free)

func _process(delta):
	if is_fading: return

	# Dragon Breath Logic
	if type == "dragon_breath":
		_process_dragon_breath(delta)
		return

	life -= delta
	if life <= 0:
		fade_out()
		return

	# Roar Logic
	if type == "roar":
		scale += Vector2(delta, delta) * speed * 0.01
		modulate.a = max(0, modulate.a - delta * 0.8)
		if has_node("WaveLine"):
			var line = get_node("WaveLine")
			line.width += delta * 15.0

	# Roar Logic
	if type == "roar":
		scale += Vector2(delta, delta) * speed * 0.01
		modulate.a = max(0, modulate.a - delta * 0.8)
		# No movement for roar, it expands from center (or source) usually,
		# but if it's a projectile, it might move.
		# If it acts like a wave, we expand it. If it moves like a projectile, we move it.
		# Ref implies it's a "projectile" replacement for Cannon, so it likely moves?
		# Or Cannon was "swarm_wave" which expands.
		# "Roar" sounds like it expands. "Cannon" desc was "swarm_wave".
		# Let's assume it expands like swarm_wave but looks different.
		pass

	var direction = Vector2.RIGHT.rotated(rotation)

	if is_instance_valid(target):
		var target_dir = (target.global_position - global_position).normalized()
		direction = target_dir
		rotation = direction.angle() # Turn entire node to face target

	position += direction * speed * delta

	# Visual Rotation (Spin)
	if visual_node:
		visual_node.rotation += delta * 15.0

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
				dragon_breath_timer = 3.0 # Duration
		else:
			state = State.HOVERING
			dragon_breath_timer = 2.0

	elif state == State.HOVERING:
		dragon_breath_timer -= delta
		if dragon_breath_timer <= 0:
			fade_out()
			return

		# Pull/Damage enemies
		var pull_radius = 150.0
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < pull_radius:
				var pull_dir = (global_position - enemy.global_position).normalized()
				enemy.global_position += pull_dir * 100.0 * delta # Pull speed
				enemy.take_damage(damage * delta, source_unit, damage_type) # DoT

func _on_area_2d_area_entered(area):
	if is_fading: return
	if type == "dragon_breath": return

	if area.is_in_group("enemies"):
		if area in hit_list: return

		# Apply Damage
		var final_damage_type = damage_type
		if is_critical:
			final_damage_type = "crit"

		area.take_damage(damage, source_unit, final_damage_type)

		# Apply Status Effects
		if effects.get("burn", 0.0) > 0.0:
			area.effects["burn"] = max(area.effects["burn"], effects["burn"])
		if effects.get("poison", 0.0) > 0.0:
			area.effects["poison"] = max(area.effects["poison"], effects["poison"])
		if effects.get("slow", 0.0) > 0.0:
			area.slow_timer = max(area.slow_timer, effects["slow"])
		if effects.get("freeze", 0.0) > 0.0:
			# Freeze stops movement and attacks
			# Implemented via temp_speed_mod = 0 and attack blocking in Enemy
			# Using slow_timer variable in Enemy?
			# Enemy.gd has slow_timer which halves speed.
			# I might need to add "freeze_timer" to Enemy.gd or use existing system.
			# Let's check Enemy.gd...
			# Enemy.gd doesn't have freeze_timer.
			# I'll rely on slow_timer for now but set it to 2.0?
			# Wait, "Snowman ... is_frozen = true (stop moving/attacking 2s)".
			# I should add `freeze_timer` to Enemy.gd or just add the property dynamically.
			area.set("freeze_timer", max(area.get("freeze_timer") if area.get("freeze_timer") else 0.0, effects["freeze"]))

		# Lifesteal Logic (Moved from Unit.gd to avoid non-standard signals)
		if source_unit and is_instance_valid(source_unit) and source_unit.unit_data.get("trait") == "lifesteal":
			var lifesteal_pct = source_unit.unit_data.get("lifesteal_percent", 0.0)
			# Estimate heal based on raw damage for simplicity or use final calculated logic
			# Here damage is already calculated (final_damage set in CombatManager passed to Projectile)
			var heal_amt = damage * lifesteal_pct
			if heal_amt > 0:
				# Heal Core
				GameManager.damage_core(-heal_amt)
				GameManager.spawn_floating_text(source_unit.global_position, "+%d" % int(heal_amt), Color.GREEN)

		# Trap Spawning Logic
		if source_unit and is_instance_valid(source_unit) and randf() < 0.25:
			var trap_type = ""
			match source_unit.type_key:
				"scorpion": trap_type = "fang"
				"viper": trap_type = "poison"
				"spider": trap_type = "mucus"

			if trap_type != "":
				if GameManager.grid_manager and GameManager.grid_manager.has_method("try_spawn_trap"):
					GameManager.grid_manager.try_spawn_trap(area.global_position, trap_type)

		hit_list.append(area)

		# 1. Bounce/Chain Logic
		# Chain is treated essentially as bounce in the reference
		var total_bounce = bounce + chain
		var bounced = false

		if total_bounce > 0:
			bounced = perform_bounce(area)

		# 2. Pierce & Split Logic
		if not bounced:
			if type == "roar":
				pass
			elif pierce > 0:
				pierce -= 1
			else:
				if split > 0 and type != "roar":
					perform_split()
				fade_out()


func _setup_simple_visual(color, shape):
	if visual_node: visual_node.hide()
	if has_node("ColorRect"): get_node("ColorRect").hide()

	var poly = Polygon2D.new()
	var points = PackedVector2Array()

	if shape == "circle":
		var radius = 6.0
		for i in range(12):
			var angle = (i * TAU) / 12
			points.append(Vector2(cos(angle), sin(angle)) * radius)
	elif shape == "blob":
		# Irregular blob
		points = PackedVector2Array([
			Vector2(-4, -6), Vector2(4, -5),
			Vector2(7, 2), Vector2(2, 6),
			Vector2(-5, 5), Vector2(-7, 0)
		])
	elif shape == "triangle":
		points = PackedVector2Array([Vector2(8, 0), Vector2(-4, -4), Vector2(-4, 4)])
	elif shape == "star":
		# Simple 4-point star
		points = PackedVector2Array([
			Vector2(6, 0), Vector2(2, 2),
			Vector2(0, 6), Vector2(-2, 2),
			Vector2(-6, 0), Vector2(-2, -2),
			Vector2(0, -6), Vector2(2, -2)
		])
	else:
		# Box
		points = PackedVector2Array([Vector2(-4,-4), Vector2(4,-4), Vector2(4,4), Vector2(-4,4)])

	poly.polygon = points
	poly.color = color
	add_child(poly)

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
			"source": source_unit,
			"damageType": damage_type
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


func _setup_snowball():
	if visual_node: visual_node.hide()
	if has_node("ColorRect"): get_node("ColorRect").hide()

	var circle = Polygon2D.new()
	var points = PackedVector2Array()
	var radius = 8.0
	for i in range(16):
		var angle = (i * TAU) / 16
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	circle.polygon = points
	circle.color = Color.WHITE
	add_child(circle)

	# Trail
	var trail = Line2D.new()
	trail.width = 4
	trail.default_color = Color(0.8, 0.9, 1.0, 0.5)
	trail.set_script(load("res://src/Scripts/Effects/Trail.gd") if ResourceLoader.exists("res://src/Scripts/Effects/Trail.gd") else null) # Optional trail script
	# Simple trail manually?
	# Let's stick to simple visual

func _setup_web():
	if visual_node: visual_node.hide()
	if has_node("ColorRect"): get_node("ColorRect").hide()

	# Draw a web shape
	var web = Line2D.new()
	web.width = 1.5
	web.default_color = Color.WEB_GRAY

	# Star/Web shape
	var points = []
	for i in range(5):
		var angle = i * (TAU / 5)
		points.append(Vector2(cos(angle), sin(angle)) * 10.0)
		points.append(Vector2.ZERO) # Return to center for web look
		points.append(Vector2(cos(angle), sin(angle)) * 5.0) # Inner web

	web.points = PackedVector2Array(points)
	add_child(web)

	# Rotation handled in _process
func _setup_stinger():
	if visual_node: visual_node.hide()

	# Yellow/Black long triangle or line
	var poly = Polygon2D.new()
	# Narrow triangle
	poly.polygon = PackedVector2Array([Vector2(-5, -2), Vector2(10, 0), Vector2(-5, 2)])
	poly.color = Color.YELLOW

	# Add a black line in middle or border
	var line = Line2D.new()
	line.points = PackedVector2Array([Vector2(-5, 0), Vector2(10, 0)])
	line.width = 1.0
	line.default_color = Color.BLACK

	add_child(poly)
	add_child(line)

func _setup_roar():
	if visual_node: visual_node.hide()

	# Transparent white/pale yellow ripple rings
	# Since _draw is not easily accessible without overriding, we can use Line2D as rings or a sprite.
	# Or we can attach a Node2D script that has _draw.
	# But simpler: Use Line2D to draw a circle (many points)

	var line = Line2D.new()
	var points = []
	var radius = 20.0
	var segments = 24
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	line.points = PackedVector2Array(points)
	line.width = 2.0
	line.default_color = Color(1.0, 1.0, 0.8, 0.4) # Pale yellow transparent
	line.closed = true
	add_child(line)

	# Maybe a second ring
	var line2 = line.duplicate()
	line2.scale = Vector2(0.7, 0.7)
	add_child(line2)

func _setup_dragon_breath():
	if visual_node: visual_node.hide()

	# Orange-red fire particles or irregular polygon
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()

	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5.0
	material.gravity = Vector3.ZERO
	material.spread = 20.0
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	# Direction is handled by node rotation

	# Color ramp: Yellow -> Red -> Dark
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 0.0)) # Yellow
	gradient.add_point(0.5, Color(1.0, 0.0, 0.0)) # Red
	gradient.set_color(1, Color(0.2, 0.0, 0.0, 0.0)) # Dark transparent

	var grad_tex = GradientTexture1D.new()
	grad_tex.gradient = gradient
	material.color_ramp = grad_tex
	material.scale_min = 2.0
	material.scale_max = 4.0

	particles.process_material = material
	particles.lifetime = 0.5
	particles.amount = 30

	# Create a simple texture
	var img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex = ImageTexture.create_from_image(img)
	particles.texture = tex

	add_child(particles)

	# Optional: Irregular polygon as core
	var poly = Polygon2D.new()
	var pts = []
	for i in range(6):
		var angle = i * TAU / 6
		var r = randf_range(5.0, 10.0)
		pts.append(Vector2(cos(angle), sin(angle)) * r)
	poly.polygon = PackedVector2Array(pts)
	poly.color = Color(1.0, 0.4, 0.0, 0.7) # Orange
	add_child(poly)

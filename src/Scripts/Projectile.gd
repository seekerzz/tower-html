extends Area2D

var target = null # Enemy node
var speed: float = 400.0
var damage: float = 10.0
var life: float = 2.0
var type: String = "pinecone"
var hit_list = []
var shared_hit_list_ref: Array = []
var source_unit = null
var effects: Dictionary = {}

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

# Visuals
var visual_node: Node2D = null
var is_fading: bool = false

# Dragon Breath State
enum State { MOVING, HOVERING, STUCK, RETURNING }
var state = State.MOVING
var dragon_breath_timer: float = 0.0

# Quill State
var quill_original_target_pos: Vector2 = Vector2.ZERO
var quill_stuck_pos: Vector2 = Vector2.ZERO

const PROJECTILE_SCENE = preload("res://src/Scenes/Game/Projectile.tscn")

func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_handle_hit):
		area_entered.connect(_handle_hit)

func setup(start_pos, target_node, dmg, proj_speed, proj_type, incoming_stats = {}):
	position = start_pos
	target = target_node
	damage = dmg
	speed = proj_speed
	type = proj_type
	stats = incoming_stats

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

	if stats.has("life"):
		life = stats.get("life")

	if stats.has("shared_hit_list"):
		shared_hit_list_ref = stats.get("shared_hit_list")

	if stats.has("is_meteor"):
		is_meteor_falling = true
		meteor_target = stats["ground_pos"]
		type = "fireball" # Reuse dragon breath or fireball visual if available, using dragon_breath as fallback if fireball not defined
		if proj_type == "fireball": pass # Already set
		else: type = "dragon_breath" # Use dragon breath visual as base if fireball not specific

		# Override type to ensure visual works? Let's check visuals.
		# Code has `_setup_dragon_breath`, no `_setup_fireball`.
		# So I will set type to "dragon_breath" for visual, or just assume "fireball" triggers something else?
		# Actually, `setup` sets `type = proj_type` earlier.
		# In CombatManager, we passed `proj: "fireball"`.
		# But Projectile.gd doesn't seem to have "fireball" in setup.
		# Let's map "fireball" to "dragon_breath" visual or create a simple one.
		if type == "fireball":
			type = "dragon_breath"

		speed = 1200.0
		rotation = (meteor_target - position).angle()

	# Initial rotation
	if not is_meteor_falling:
		if target and is_instance_valid(target):
			look_at(target.global_position)
		if type == "quill":
			quill_original_target_pos = target.global_position
		elif stats.get("angle") != null:
			rotation = stats.get("angle")

	# Visual Separation
	if has_node("Sprite2D"):
		visual_node = get_node("Sprite2D")
	elif has_node("Polygon2D"):
		visual_node = get_node("Polygon2D")

	if type == "black_hole_field":
		_setup_black_hole_field()
		speed = 0.0
		# Use stats for life/duration if available
		if stats.has("duration"):
			life = stats["duration"]

	if stats.get("hide_visuals", false):
		if visual_node: visual_node.hide()
		if has_node("ColorRect"): get_node("ColorRect").hide()
		modulate.a = 0.0

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
	elif type == "pollen":
		_setup_simple_visual(Color.PINK, "star")
	elif type == "quill":
		# Extend life for quills to ensure they can be recalled
		life = 10.0
		_setup_quill()
	elif type == "lightning":
		# Keep lightning if it was handled elsewhere or add simple visual
		_setup_simple_visual(Color.CYAN, "line")

func fade_out():
	if is_fading: return
	if state == State.STUCK: return # Stuck quills don't fade out by time alone usually, but we need life check

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

	# Dragon Breath Logic
	if type == "dragon_breath":
		_process_dragon_breath(delta)
		return

	# Quill Logic (Returning check)
	if type == "quill" and state == State.RETURNING:
		# Standard movement handles the position update towards target (source_unit)
		# We just need to check arrival
		if target and is_instance_valid(target):
			if global_position.distance_to(target.global_position) < 15.0:
				queue_free()
				return
		else:
			# Source died
			queue_free()
			return

	# Black Hole Logic
	if type == "black_hole_field":
		_process_black_hole(delta)
		# fallthrough to life check

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

	var direction = Vector2.RIGHT.rotated(rotation)

	if is_instance_valid(target):
		var target_dir = (target.global_position - global_position).normalized()
		direction = target_dir
		rotation = direction.angle() # Turn entire node to face target

	position += direction * speed * delta

	# Visual Rotation (Spin)
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

			# Mass calculation
			var mass = 1.0
			if "mass" in enemy:
				mass = enemy.mass
			elif "knockback_resistance" in enemy:
				# Use resistance as mass proxy
				mass = max(enemy.knockback_resistance, 1.0)
			elif "radius" in enemy:
				mass = max(enemy.radius, 1.0)
			elif "hpMod" in enemy:
				mass = max(enemy.hpMod * 10.0, 1.0)

			# Boss resistance/immunity check if needed, but logic implies high mass reduces pull
			mass = max(mass, 0.1)

			var force_magnitude = (pull_strength / max(dist, 10.0)) * (1.0 / mass)
			var force_vector = dir * force_magnitude * delta

			# Apply force
			if enemy.has_method("apply_force"):
				enemy.apply_force(force_vector)
			else:
				# Direct position modification (works on top of physics for control effects)
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

func _on_body_entered(body):
	_handle_hit(body)

func _handle_hit(target_node):
	if is_fading: return
	if type == "dragon_breath": return
	if type == "black_hole_field": return # Black hole doesn't hit/destroy on contact, it pulls
	if type == "quill" and state == State.STUCK: return

	if target_node.is_in_group("enemies"):
		if shared_hit_list_ref != null and target_node in shared_hit_list_ref: return
		if target_node in hit_list: return

		# Quill Return Logic (Pull)
		if type == "quill" and state == State.RETURNING:
			var pull_str = 0.0
			if source_unit and source_unit.unit_data.has("levels"):
				var lvl_stats = source_unit.unit_data["levels"][str(source_unit.level)]
				if lvl_stats.has("mechanics"):
					pull_str = lvl_stats["mechanics"].get("pull_strength", 0.0)

			if pull_str > 0:
				var dir = (source_unit.global_position - target_node.global_position).normalized()
				# Pull enemy
				# Apply a significant tug since this is a one-shot hit event
				# Using a fixed time-slice equivalent (e.g. 0.1s) to make the pull noticeable
				target_node.global_position += dir * (pull_str * 0.05)

		# Apply Damage
		var final_damage_type = damage_type
		if is_critical:
			final_damage_type = "crit"

		# Calculate Knockback Force
		# kb_force = damage * speed * 0.005 (coefficient)
		var kb_force = damage * speed * 0.005
		if type == "roar":
			kb_force *= 2.0 # Extra knockback for roar
		if type == "snowball":
			kb_force *= 1.5

		if target_node.has_method("take_damage"):
			target_node.take_damage(damage, source_unit, final_damage_type, self, kb_force)

		# Apply Status Effects
		if effects.get("burn", 0.0) > 0.0:
			if "effects" in target_node:
				target_node.effects["burn"] = max(target_node.effects["burn"], effects["burn"])
				if "burn_source" in target_node:
					target_node.burn_source = source_unit
		if effects.get("poison", 0.0) > 0.0:
			if target_node.has_method("apply_poison"):
				target_node.apply_poison(source_unit, 1, effects["poison"])
		if effects.get("slow", 0.0) > 0.0:
			if "slow_timer" in target_node:
				target_node.slow_timer = max(target_node.slow_timer, effects["slow"])
		if effects.get("freeze", 0.0) > 0.0:
			# Freeze stops movement and attacks
			if target_node.has_method("apply_freeze"):
				target_node.apply_freeze(effects["freeze"])
			else:
				target_node.set("freeze_timer", max(target_node.get("freeze_timer") if target_node.get("freeze_timer") else 0.0, effects["freeze"]))

		# Lifesteal Logic
		if source_unit and is_instance_valid(source_unit) and source_unit.unit_data.get("trait") == "lifesteal":
			var lifesteal_pct = source_unit.unit_data.get("lifesteal_percent", 0.0)
			var heal_amt = damage * lifesteal_pct
			if heal_amt > 0:
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
					GameManager.grid_manager.try_spawn_trap(target_node.global_position, trap_type)

		hit_list.append(target_node)
		if shared_hit_list_ref != null:
			shared_hit_list_ref.append(target_node)

		# 1. Bounce/Chain Logic
		var total_bounce = bounce + chain
		var bounced = false

		if total_bounce > 0:
			bounced = perform_bounce(target_node)

		# 2. Pierce & Split Logic
		if not bounced:
			if type == "roar":
				pass
			elif pierce > 0:
				pierce -= 1
			else:
				if split > 0 and type != "roar":
					perform_split()

				# Final Hit - Spawn visual and destroy
				_spawn_hit_visual(target_node.global_position)
				if type != "quill": # Quills don't die on hit, they pass through until Stuck logic handles them (or if they hit during return)
					print("Projectile hit final: ", type, " -> queue_free")
					queue_free()

func recall():
	# Allow recall from MOVING as well
	if state == State.RETURNING: return

	state = State.RETURNING

	# Target becomes source (return to owner)
	target = source_unit

	# Increase speed for return if desired
	speed = 800.0 # Or speed * 2.0

	# Ensure it penetrates everything on way back
	pierce = 999

	# Clear hit list to hit enemies again
	hit_list.clear()
	if shared_hit_list_ref != null:
		# If shared list exists, we might not want to clear it if other quills share it?
		# But 'hit_list' is local. shared is for swing. Quills usually don't use shared list unless specified.
		# Assuming safe to just clear local hit_list which blocks re-hits.
		pass

	# Re-enable collision
	set_deferred("monitoring", true)

	# Visual update
	if visual_node:
		visual_node.modulate = Color.RED # Highlight return

func _setup_quill():
	if visual_node: visual_node.hide()

	# Thin sharp triangle
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(10, 0), Vector2(-10, -3), Vector2(-10, 3)])
	poly.color = Color.DARK_GRAY

	var line = Line2D.new()
	line.points = PackedVector2Array([Vector2(-10, 0), Vector2(10, 0)])
	line.width = 1.0
	line.default_color = Color.WHITE

	add_child(poly)
	add_child(line)

func _spawn_hit_visual(pos: Vector2):
	var effect = load("res://src/Scripts/Effects/SlashEffect.gd").new()
	get_parent().add_child(effect)
	effect.global_position = pos
	effect.rotation = randf() * TAU

	var shape = "circle"
	var col = Color.WHITE

	if type == "pinecone":
		shape = "circle"
		col = Color("8B4513") # SaddleBrown
	elif type == "ink":
		shape = "blob"
		col = Color.BLACK
	elif type == "stinger":
		shape = "triangle"
		col = Color.YELLOW
	elif type == "pollen":
		shape = "star"
		col = Color.PINK
	else:
		# Fallback defaults
		shape = "slash"
		col = Color.WHITE

	effect.configure(shape, col)
	effect.play()

func _on_meteor_hit():
	is_meteor_falling = false

	# Momentum Bounce Logic
	# Current rotation is the incidence angle.
	# Bounce angle = rotation + randf_range(-0.5, 0.5) (approx +/- 30 deg)
	var bounce_angle = rotation + randf_range(-0.5, 0.5)
	rotation = bounce_angle

	# Reset Stats
	life = 0.3 # 快速消散
	speed = 50.0 # 强摩擦力
	target = null

	# Visual Splash
	# Existing SlashEffect logic in codebase uses .new() on the script, so we follow that pattern.
	var SlashEffectScript = load("res://src/Scripts/Effects/SlashEffect.gd")
	if SlashEffectScript:
		var slash = SlashEffectScript.new()
		get_parent().add_child(slash)
		slash.global_position = global_position
		slash.rotation = rotation
		slash.modulate = Color.ORANGE
		slash.play()

	type = "meteor_debris"

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

func _setup_black_hole_field():
	if visual_node: visual_node.hide()

	var color_hex = stats.get("skillColor", "#330066")
	var color = Color(color_hex)
	self.modulate = color # Apply modulation to entire node (including children we add)

	# Create visual representation
	var poly = Polygon2D.new()
	var points = PackedVector2Array()
	var r = 20.0
	var steps = 16
	for i in range(steps):
		var angle = (i * TAU) / steps
		# slightly irregular for effect
		var rad = r + randf_range(-2, 2)
		points.append(Vector2(cos(angle), sin(angle)) * rad)

	poly.polygon = points
	poly.color = Color(1, 1, 1, 0.8) # Base white, modulated by self.modulate
	add_child(poly)

	# Rotation Tween
	var tween = create_tween().set_loops()
	tween.tween_property(poly, "rotation", TAU, 2.0).from(0.0)

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

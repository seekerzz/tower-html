extends Node2D

@onready var label = $Label

# Physics properties
var velocity: Vector2 = Vector2.ZERO
var gravity: float = 1600.0
var friction: float = 4.0
var move_direction: Vector2 = Vector2.ZERO
var initial_pos: Vector2
var fade_start_dist: float = 100.0

# Effect properties
var is_crit_hit: bool = false
var shake_amount: float = 2.0
var base_pos_offset: Vector2 = Vector2.ZERO

func setup(value_str: String, color: Color, is_crit: bool = false, value_num: float = 0.0, direction: Vector2 = Vector2.ZERO):
	label.text = value_str
	is_crit_hit = is_crit
	z_index = 200 if is_crit else 100

	# 1. Pivot Center
	# Ensure label size is calculated or set to center it
	if label.size == Vector2.ZERO:
		label.size = Vector2(100, 50) # Estimate if not set, or let layout handle it.
		# Ideally, wait for resize? But setup is called after instantiation.
		# Let's set pivot_offset to center.
	label.pivot_offset = label.size / 2.0

	# 2. Scale & Pop Animation
	var base_scale = clamp(1.0 + (value_num / 500.0), 1.0, 2.5)
	if is_crit:
		base_scale *= 1.5

	scale = Vector2(0.2, 0.2) # Initial tiny scale

	var tween = create_tween()
	# Phase 1: Explosion (Overshoot)
	tween.tween_property(self, "scale", Vector2(base_scale * 1.5, base_scale * 1.5), 0.05)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Phase 2: Settle (Back)
	tween.tween_property(self, "scale", Vector2(base_scale, base_scale), 0.15)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 3. Color Flash
	label.modulate = Color(2.0, 2.0, 2.0) # Flash White (HDR)
	var color_tween = create_tween()
	color_tween.tween_property(label, "modulate", color, 0.2)

	# 4. Physics / Movement
	initial_pos = position

	if direction != Vector2.ZERO:
		move_direction = direction
		# Scatter +/- 15 degrees
		var angle = randf_range(-deg_to_rad(15), deg_to_rad(15))
		move_direction = move_direction.rotated(angle)

		# High velocity, High friction
		var speed = 800.0 if is_crit else 500.0
		velocity = move_direction * speed

		# Directional text: Gravity affects it?
		# Prompt says: "gravity 提高到 1600.0 (增加重量感)". Usually directional text (knockback) flies horizontally.
		# If we apply gravity to horizontal text, it will arc down. That sounds good for "juiciness".
		# Unless it's top-down. This game is top-down?
		# Context: "CombatManager", "GridManager", "Tower Defense" style?
		# "GridManager" implies top-down.
		# If top-down, gravity means "falling down the screen" (Y+).
		# If "direction" is (1, 0), and gravity is Y+, it will curve down.
		# If "direction" is UP (0, -1), it will go up and fall back.
		# If the game is top-down 2D, "gravity" usually isn't real unless simulating height.
		# But typical "juicy" text falls down.
		# Let's apply gravity to ALL text to give it weight.
	else:
		# Standard pop-up
		move_direction = Vector2.ZERO
		var spread = 200.0 if is_crit else 100.0
		var jump = -600.0 if is_crit else -400.0 # Higher jump to counter high gravity
		velocity = Vector2(randf_range(-1, 1) * spread, randf_range(jump, jump * 0.5))

func _process(delta):
	# Apply Gravity
	velocity.y += gravity * delta

	# Apply Friction (Drag)
	# Friction should reduce velocity magnitude
	# "move_toward" is linear friction. "velocity *= (1.0 - friction * delta)" is exponential.
	# Prompt says "friction 提高到 4.0". If we use move_toward: 4.0 * delta is tiny for pixel speeds (500).
	# Probably means viscous friction factor.
	# Let's use linear drag for "move_toward 0" but with a high value?
	# Or multiplicative?
	# Let's try multiplicative for "air resistance".
	# velocity = velocity.move_toward(Vector2.ZERO, friction * 300.0 * delta) # 4 * 300 = 1200 px/s deceleration
	# Or simpler:
	velocity = velocity.lerp(Vector2.ZERO, friction * delta)

	position += velocity * delta

	# Crit Shake
	if is_crit_hit:
		var shake_period = 0.2
		if scale.x > 0.0: # Just a check to see if we are alive/visible
			# We need to know time since start? Or just shake always?
			# "在生命周期的前 0.2秒内"
			# We don't have a timer variable here easily without adding one.
			# But we can check scale tween state? No.
			# Let's check distance traveled? No.
			# Let's just add a timer or check if velocity is still high?
			# Or just check if scale is still changing (approx < 0.2s)?
			# Let's add a small timer or use `Time.get_ticks_msec()` diff?
			# Simpler: Just shake while velocity is high?
			# Prompt: "在生命周期的前 0.2秒内"
			# Let's use an internal timer variable if strictly needed, or just `get_tree().create_timer`?
			# No, `_process` runs every frame.
			# Let's check `modulate`? It takes 0.2s to fade to color.
			if label.modulate.r > 1.2 or label.modulate.g > 1.2 or label.modulate.b > 1.2:
				# Still flashing (approx < 0.2s)
				var offset = Vector2(randf(), randf()) * shake_amount
				# We can't just set position because position is driven by physics.
				# We should set `label.position` offset?
				label.position = offset - (label.size / 2.0) # Keep centered + offset
			else:
				label.position = -(label.size / 2.0) # Reset to centered

	# Fade Out Logic
	var dist = position.distance_to(initial_pos)
	if dist > fade_start_dist:
		modulate.a -= delta * 5.0
		if modulate.a <= 0:
			queue_free()

	# Also fade if speed drops too low (stopped)
	if velocity.length() < 20.0:
		modulate.a -= delta * 3.0
		if modulate.a <= 0:
			queue_free()

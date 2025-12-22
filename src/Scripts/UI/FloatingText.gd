extends Node2D

@onready var label = $Label

# Physics properties
var velocity: Vector2 = Vector2.ZERO
var gravity: float = 1200.0
var friction: float = 4.0
var initial_pos: Vector2
var fade_start_dist: float = 100.0

# Effect properties
var is_crit_hit: bool = false
var shake_amount: float = 2.0

func setup(value_str: String, color: Color, is_crit: bool = false, value_num: float = 0.0, direction: Vector2 = Vector2.ZERO):
	label.text = value_str
	is_crit_hit = is_crit
	z_index = 200 if is_crit else 100

	initial_pos = position

	# 1. Pivot Center
	if label.size == Vector2.ZERO:
		label.size = Vector2(100, 50)
	label.pivot_offset = label.size / 2.0

	# 2. Scale & Pop Animation (Juice)
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

	# 3. Color Flash (Juice)
	label.modulate = Color(1.5, 1.5, 1.5) # Bright White Flash
	var color_tween = create_tween()
	color_tween.tween_property(label, "modulate", color, 0.2)

	# 4. Physics / Movement Logic (Hybrid System)

	if direction != Vector2.ZERO:
		# --- Directional Mode (Bullet-like Trajectory) ---
		gravity = 200.0 # Very low gravity for straight flight

		# Slight upward correction to avoid floor dragging
		var adjust_dir = (direction.normalized() + Vector2(0, -0.15)).normalized()

		# High speed + High friction = Fast burst then stop
		var speed = 900.0 if is_crit else 600.0
		velocity = adjust_dir * speed
	else:
		# --- Random Mode (Jump/Pop-up) ---
		gravity = 1200.0 # High gravity for bounce

		var spread = 200.0 if is_crit else 100.0
		var jump = -600.0 if is_crit else -400.0
		velocity = Vector2(randf_range(-1, 1) * spread, randf_range(jump, jump * 0.5))

func _process(delta):
	# Apply Gravity
	velocity.y += gravity * delta

	# Apply Friction (Air Resistance)
	# Use move_toward for linear drag (simulating strong air resistance)
	velocity = velocity.move_toward(Vector2.ZERO, friction * 100.0 * delta)

	# Update Position
	position += velocity * delta

	# Crit Shake (Instability)
	if is_crit_hit:
		# Simple check: if still flashing (modulate is bright), apply shake
		if label.modulate.r > 1.2 or label.modulate.g > 1.2 or label.modulate.b > 1.2:
			var offset = Vector2(randf(), randf()) * shake_amount
			label.position = offset - (label.size / 2.0) # Keep centered + offset
		else:
			label.position = -(label.size / 2.0) # Reset to centered

	# Fade Out Logic
	var dist = position.distance_to(initial_pos)

	# Fade if far away OR if velocity is low (stopped)
	if dist > fade_start_dist or velocity.length() < 20.0:
		# Start fading
		# Only fade if velocity is low or distance is very high, to prevent fading mid-flight if it's just moving fast?
		# No, the logic requested is "fade out and destroy".
		# Let's start fading when stopped.
		if velocity.length() < 50.0 or dist > fade_start_dist * 2.0:
			modulate.a -= delta * 5.0
			if modulate.a <= 0:
				queue_free()

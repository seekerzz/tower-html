extends Node2D

@onready var label = $Label

# Physics parameters (Juicy)
var velocity: Vector2 = Vector2.ZERO
var gravity: float = 1600.0
var friction: float = 4.0

# State
var initial_pos: Vector2
var fade_start_dist: float = 100.0
var move_direction: Vector2 = Vector2.ZERO
var is_directional: bool = false
var is_critical: bool = false
var shake_timer: float = 0.0

func setup(value_str: String, color: Color, is_crit: bool = false, value_num: float = 0.0, direction: Vector2 = Vector2.ZERO):
	is_critical = is_crit
	label.text = value_str
	z_index = 200 if is_crit else 100

	# Pivot Center
	if label.size == Vector2.ZERO:
		# Force update if size not ready (usually it isn't in setup, so we estimate or await)
		# But since it's a Label, it might resize automatically.
		# Setting pivot_offset on Label often requires size.
		# Let's try to set it based on estimation or defer?
		# Or better: Center the Label node relative to Node2D position (0,0) using anchors/position.
		# If Label is centered via grow_horizontal = BOTH, then position is center.
		# But user asked to set pivot_offset.
		# Let's set it after frame? No, needs to be instant.
		# Let's assume layout is centered. If not, setting pivot_offset is good.
		label.reset_size() # Ensure size is calculated
		label.pivot_offset = label.size / 2.0
	else:
		label.pivot_offset = label.size / 2.0

	# Scale Calculation
	var base_scale = clamp(1.0 + (value_num / 500.0), 1.0, 2.5)
	if is_crit:
		base_scale *= 1.5

	# Initial State
	scale = Vector2(0.2, 0.2)
	initial_pos = position

	# --- 1. Pop Animation (Juicy) ---
	var tween = create_tween()
	# Phase 1: Overshoot (0.05s)
	tween.tween_property(self, "scale", Vector2(base_scale * 1.5, base_scale * 1.5), 0.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Phase 2: Rebound (0.15s)
	tween.tween_property(self, "scale", Vector2(base_scale, base_scale), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# --- 2. Flash Effect ---
	# Start bright white (HDR if possible, or just >1)
	label.modulate = Color(2.0, 2.0, 2.0) if is_crit else Color(1.5, 1.5, 1.5)
	var color_tween = create_tween()
	color_tween.tween_property(label, "modulate", color, 0.2) # Fade to normal color

	# --- 3. Physics Setup ---
	if direction != Vector2.ZERO:
		is_directional = true
		move_direction = direction.normalized()
		# Scatter +/- 15 deg
		var angle_offset = deg_to_rad(randf_range(-15, 15))
		move_direction = move_direction.rotated(angle_offset)

		# Higher initial speed for juicy drag
		var speed = 700.0 if is_crit else 500.0
		velocity = move_direction * speed
		rotation = move_direction.angle()
	else:
		# Random Jump (Non-directional)
		rotation_degrees = randf_range(-15, 15)
		var spread = 200.0 if is_crit else 100.0
		var jump = -600.0 if is_crit else -450.0 # Higher jump for stronger gravity
		velocity = Vector2(randf_range(-1, 1) * spread, randf_range(jump, jump * 0.5))

	if is_crit:
		shake_timer = 0.2

func _process(delta):
	# Physics
	if is_directional:
		# High friction drag
		# Using lerp-like friction for "air resistance" feel: v = v * (1 - f * dt)
		# Or move_toward. move_toward is linear deceleration.
		# User requested "Large friction... rapid deceleration".
		# Let's use linear deceleration but large value.
		var drag = friction * 200.0
		velocity = velocity.move_toward(Vector2.ZERO, drag * delta)
		position += velocity * delta
	else:
		# Standard Gravity Physics
		velocity.y += gravity * delta
		velocity.x = move_toward(velocity.x, 0, friction * 50.0 * delta)
		position += velocity * delta

	# Crit Shake
	if is_critical and shake_timer > 0:
		shake_timer -= delta
		var shake_amount = 3.0 * (shake_timer / 0.2) # Fade out shake
		var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amount
		# Apply offset visually (we can't easily offset position without drifting,
		# so we offset the label or just jitter position.
		# If we jitter position, we alter trajectory. Better to jitter visuals only.)
		# But `position` is the Node2D position.
		# Let's jitter `label.position` or `visual_node`.
		# Label is at (0,0) usually.
		label.position = -label.pivot_offset + offset # Pivot offset is roughly center, so we need to account for it if we set it?
		# Wait, if pivot_offset is set, it affects rotation/scale, not position directly unless we move it.
		# Label default pos is (0,0). If we set pivot_offset to size/2, it rotates around center.
		# We should just offset from (0,0).
		label.position = offset
	elif is_critical:
		label.position = Vector2.ZERO # Reset

	# Distance Fade
	var dist = position.distance_to(initial_pos)
	if dist > fade_start_dist:
		modulate.a -= delta * 5.0
		if modulate.a <= 0:
			queue_free()

	# Safety Timeout (e.g. if it hits a wall or stops before fade distance)
	# (Optional, but good practice if fade relies on distance)

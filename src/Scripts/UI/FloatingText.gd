extends Node2D

@onready var label = $Label
var velocity: Vector2 = Vector2.ZERO
var gravity: float = 1200.0
var friction: float = 2.0

var initial_pos: Vector2
var fade_start_dist: float = 100.0
var move_direction: Vector2 = Vector2.ZERO
var is_directional: bool = false

func setup(value_str: String, color: Color, is_crit: bool = false, value_num: float = 0.0, direction: Vector2 = Vector2.ZERO):
	label.text = value_str
	# Brighten color for crit
	label.modulate = color.lightened(0.2) if is_crit else color
	z_index = 200 if is_crit else 100

	# Dynamic scaling calculation
	# Scale grows with damage, capped at 2.5x
	var base_scale = clamp(1.0 + (value_num / 500.0), 1.0, 2.5)
	if is_crit:
		base_scale *= 1.5

	# Initial State
	scale = Vector2.ZERO
	initial_pos = position

	# Elastic Pop Animation
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(base_scale, base_scale), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	if direction != Vector2.ZERO:
		is_directional = true
		move_direction = direction.normalized()
		# Add random scatter (+/- 15 degrees)
		var angle_offset = deg_to_rad(randf_range(-15, 15))
		move_direction = move_direction.rotated(angle_offset)

		var speed = 400.0 if is_crit else 250.0
		velocity = move_direction * speed
		rotation = move_direction.angle()
	else:
		# Original Random Jump Logic
		rotation_degrees = randf_range(-15, 15)
		var spread = 200.0 if is_crit else 100.0
		var jump = -450.0 if is_crit else -300.0
		velocity = Vector2(randf_range(-1, 1) * spread, randf_range(jump, jump * 0.5))

	# Note: Removed time-based fade tween. Fade is now handled in _process.

func _process(delta):
	if is_directional:
		# Directional movement: constant velocity (maybe slight friction or just constant)
		# User said "move along that direction", "speed affected by crit".
		# Let's keep velocity constant or apply slight drag?
		# "fast fade out after distance".
		# For "impact" feel, maybe it slows down?
		# But "fly out" usually implies momentum. Let's keep constant velocity or slight friction.
		# Let's apply slight friction to make it look physics-y but maintain direction.
		velocity = velocity.move_toward(Vector2.ZERO, friction * 50.0 * delta)
		position += velocity * delta
	else:
		# Original Physics
		velocity.y += gravity * delta
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		position += velocity * delta

	# Distance / Fade Logic
	var dist = position.distance_to(initial_pos)
	if dist > fade_start_dist:
		# Fast fade out
		modulate.a -= delta * 5.0
		if modulate.a <= 0:
			queue_free()

	# Fallback timer (in case it doesn't move far enough, e.g. stuck or zero velocity)
	# or just rely on modulate.a logic if we ensure it moves or we add a lifetime.
	# But original logic had lifetime. Let's add a safety timeout just in case.
	# But strictly following instructions: "Remove time-based Tween fade out... calculate distance".
	# If direction is zero (random jump), does it travel 100 distance?
	# Random jump: vy starts at -300 to -450. Gravity 1200.
	# It goes up and falls down. It will travel distance.
	# If it stays near 0 (e.g. falls back to start), it might persist.
	# So for non-directional (gravity), maybe we should keep a time limit or check total path length?
	# The instruction says "When passed fade_start_dist...".
	# If I jump up and fall down, I might cross 100px.
	# Let's stick to the instruction. If it causes issues (lingering text), I'll fix later.
	# Actually, for the "random jump", it falls down eventually.
	# If it falls below screen, we should probably kill it.
	# But let's assume distance check works.

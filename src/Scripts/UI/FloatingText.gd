extends Node2D

@onready var label = $Label
var velocity: Vector2 = Vector2.ZERO
var gravity: float = 1200.0
var friction: float = 2.0
var move_direction: Vector2 = Vector2.ZERO
var initial_pos: Vector2
var fade_start_dist: float = 100.0

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
	rotation_degrees = randf_range(-15, 15)
	initial_pos = position

	# Elastic Pop Animation
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(base_scale, base_scale), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	if direction != Vector2.ZERO:
		move_direction = direction
		# Add random scatter
		var angle = randf_range(-deg_to_rad(15), deg_to_rad(15))
		move_direction = move_direction.rotated(angle)

		var speed = 400.0 if is_crit else 250.0
		velocity = move_direction * speed

		gravity = 0 # No gravity for directional text? Or maybe slight drag?
		# User requirement: "顺着攻击（击退）的方向飞出"
		# Let's keep it simple: linear movement with drag.
		friction = 1.0 # Less friction
	else:
		# Original logic (random upward jump)
		move_direction = Vector2.ZERO
		var spread = 200.0 if is_crit else 100.0
		var jump = -450.0 if is_crit else -300.0
		velocity = Vector2(randf_range(-1, 1) * spread, randf_range(jump, jump * 0.5))
		gravity = 1200.0
		friction = 2.0

func _process(delta):
	if move_direction != Vector2.ZERO:
		# Directional movement
		velocity = velocity.move_toward(Vector2.ZERO, friction * 100 * delta)
		position += velocity * delta

		# Distance check for fade
		var dist = position.distance_to(initial_pos)
		if dist > fade_start_dist:
			modulate.a -= delta * 5.0 # Fast fade
			if modulate.a <= 0:
				queue_free()

		# Also fade if slow enough (stopped)
		if velocity.length() < 10.0:
			modulate.a -= delta * 2.0
			if modulate.a <= 0:
				queue_free()

	else:
		# Original physics
		velocity.y += gravity * delta
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		position += velocity * delta

		# Distance check for fade (Fallback if not Directional, but user asked to remove Tween fade)
		# "移除原有的基于时间的 Tween 淡出逻辑。在 _process 中计算当前位置..."
		# Since the original logic was jumping up and falling, distance from initial pos might not be the best metric if it falls back down.
		# However, usually it goes up and then down.
		# If we stick to distance, it works. Or we can just use time for non-directional?
		# The prompt says: "移除原有的基于时间的 Tween 淡出逻辑。" implying for ALL cases.

		var dist = position.distance_to(initial_pos)
		if dist > fade_start_dist * 1.5: # Slightly longer for jump
			modulate.a -= delta * 5.0
			if modulate.a <= 0:
				queue_free()
		elif velocity.y > 0 and position.y > initial_pos.y + 50: # If fell below start
			modulate.a -= delta * 5.0
			if modulate.a <= 0:
				queue_free()

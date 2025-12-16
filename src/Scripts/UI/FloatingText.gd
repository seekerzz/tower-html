extends Node2D

@onready var label = $Label
var velocity: Vector2 = Vector2.ZERO
var gravity: float = 1200.0
var friction: float = 2.0

func setup(value_str: String, color: Color, is_crit: bool = false, value_num: float = 0.0):
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

	# Elastic Pop Animation
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(base_scale, base_scale), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Physics Initial Velocity Simulation
	var spread = 200.0 if is_crit else 100.0
	var jump = -450.0 if is_crit else -300.0
	velocity = Vector2(randf_range(-1, 1) * spread, randf_range(jump, jump * 0.5))

	# Fade out and destroy
	var fade = create_tween()
	fade.tween_interval(0.7)
	fade.tween_property(self, "modulate:a", 0.0, 0.3)
	fade.tween_callback(queue_free)

func _process(delta):
	velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	position += velocity * delta

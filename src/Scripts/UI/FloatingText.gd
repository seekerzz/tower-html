extends Node2D

@onready var label = $Label
var velocity: Vector2 = Vector2.ZERO
var gravity: float = 1200.0
var friction: float = 2.0

func _ready():
	# Ensure the label has the correct visual style if not set in scene
	if label:
		# Create LabelSettings if not present (or override)
		if not label.label_settings:
			label.label_settings = LabelSettings.new()

		var settings = label.label_settings
		settings.font_size = 24
		settings.outline_size = 8
		settings.outline_color = Color.BLACK
		settings.shadow_size = 4
		settings.shadow_color = Color(0, 0, 0, 0.5)
		settings.shadow_offset = Vector2(2, 2)

		# Ensure centering
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func setup(value_str: String, color: Color, is_crit: bool = false, value_num: float = 0.0):
	if not label: return

	label.text = value_str
	# Brighten color for crits
	label.modulate = color.lightened(0.2) if is_crit else color
	z_index = 200 if is_crit else 100

	# Dynamic scaling calculation
	# Base scale 1.0, max 2.5. larger numbers = larger text.
	# Assuming damage numbers range from ~10 to ~1000+
	var base_scale = clamp(1.0 + (value_num / 500.0), 1.0, 2.5)
	if is_crit:
		base_scale *= 1.5

	# Initial state
	scale = Vector2.ZERO
	rotation_degrees = randf_range(-15, 15)

	# Elastic Pop Animation
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(base_scale, base_scale), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Physics Initial Velocity Simulation
	# Splash in random x direction, jump up in y
	var spread = 200.0 if is_crit else 100.0
	var jump = -450.0 if is_crit else -300.0
	velocity = Vector2(randf_range(-1, 1) * spread, randf_range(jump, jump * 0.5))

	# Fade out and destroy
	var fade = create_tween()
	fade.tween_interval(0.7) # Wait
	fade.tween_property(self, "modulate:a", 0.0, 0.3) # Fade out
	fade.tween_callback(queue_free)

func _process(delta):
	# Physics simulation
	velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	position += velocity * delta

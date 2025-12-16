extends Node2D

var damage: float = 20.0
var radius: float = 2.0 # In tiles approx or visual
var duration: float = 3.0
var tick_rate: float = 0.5
var timer: float = 0.0

func _ready():
	# Visuals: Red Circle or Particles
	var circle = ColorRect.new()
	circle.color = Color(1.0, 0.2, 0.0, 0.3)
	circle.size = Vector2(256, 256) # 4x4 tiles approx (4 * 64)
	circle.position = -circle.size / 2
	add_child(circle)

	# Falling "Meteors" simulated by simple particles or just changing colors
	var timer_node = Timer.new()
	timer_node.wait_time = tick_rate
	timer_node.autostart = true
	timer_node.timeout.connect(_on_tick)
	add_child(timer_node)

	await get_tree().create_timer(duration).timeout
	queue_free()

func _on_tick():
	# Deal damage to enemies in range
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) < 128: # approx 4x4 radius
			enemy.take_damage(damage, null, "fire")

	# Visual Pulse
	var pulse = ColorRect.new()
	pulse.color = Color(1, 1, 0, 0.5)
	pulse.size = Vector2(40, 40)
	pulse.position = Vector2(randf_range(-100, 100), randf_range(-100, 100))
	add_child(pulse)
	var tween = create_tween()
	tween.tween_property(pulse, "modulate:a", 0.0, 0.5)
	tween.tween_callback(pulse.queue_free)

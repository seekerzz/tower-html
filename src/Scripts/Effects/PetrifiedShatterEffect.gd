extends Node2D

var debris_pieces: Array = []

func _ready():
	_create_shatter()

func _create_shatter():
	var count = randi_range(3, 6) # 3-6 fragments

	for i in range(count):
		var debris = _create_debris()
		add_child(debris)
		debris_pieces.append(debris)

	# 2.5s delay before fade out
	var tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(_fade_out)

func _create_debris() -> RigidBody2D:
	var debris = RigidBody2D.new()

	# Random size
	var size = randf_range(10.0, 30.0)

	# Collision Shape
	var shape = RectangleShape2D.new()
	shape.size = Vector2(size, size)
	var collision = CollisionShape2D.new()
	collision.shape = shape
	debris.add_child(collision)

	# Visual
	var visual = Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-size/2, -size/2),
		Vector2(size/2, -size/2),
		Vector2(size/2, size/2),
		Vector2(-size/2, size/2)
	])
	visual.color = Color.DARK_GRAY
	debris.add_child(visual)

	# Random mass
	var m = randf_range(1.0, 3.0)
	debris.mass = m

	# Gravity Scale (1.0 default)
	debris.gravity_scale = 1.0

	# Collision Layer/Mask
	# Layer 20 = 1 << 19
	debris.collision_layer = 1 << 19
	# Mask 1 (Walls) | 20 (Others)
	debris.collision_mask = 1 | (1 << 19)

	# Random Velocity
	# Speed inversely proportional to mass
	var speed = randf_range(200.0, 400.0) / m
	var direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	if direction == Vector2.ZERO: direction = Vector2.UP

	debris.linear_velocity = direction * speed
	debris.angular_velocity = randf_range(-5.0, 5.0)

	return debris

func _fade_out():
	var tween = create_tween()
	tween.set_parallel(true)
	for debris in debris_pieces:
		if is_instance_valid(debris):
			tween.tween_property(debris, "modulate:a", 0.0, 0.5)

	tween.chain().tween_callback(queue_free)

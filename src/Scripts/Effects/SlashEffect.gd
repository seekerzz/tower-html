extends Node2D

func play():
	# Initial state
	scale = Vector2.ZERO
	modulate.a = 1.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Move slightly forward in the direction of rotation
	var move_vec = Vector2.RIGHT.rotated(rotation) * 20.0
	tween.tween_property(self, "position", position + move_vec, 0.2)

	await tween.finished
	queue_free()

func _draw():
	# Draw a white crescent/fan shape simulating a slash
	var center = Vector2.ZERO
	var radius = 20.0
	var start_angle = -PI / 3
	var end_angle = PI / 3
	var point_count = 32
	var color = Color.WHITE

	var points = PackedVector2Array()

	for i in range(point_count + 1):
		var t = float(i) / point_count
		var angle = lerp(start_angle, end_angle, t)
		var dir = Vector2(cos(angle), sin(angle))

		# Taper thickness: thick in middle (t=0.5), thin at edges
		var thickness = 10.0 * sin(t * PI)

		points.append(dir * (radius + thickness / 2.0))

	# Create inner edge
	for i in range(point_count, -1, -1):
		var t = float(i) / point_count
		var angle = lerp(start_angle, end_angle, t)
		var dir = Vector2(cos(angle), sin(angle))

		var thickness = 10.0 * sin(t * PI)
		points.append(dir * (radius - thickness / 2.0))

	draw_colored_polygon(points, color)

extends Node2D

func _draw():
	var parent = get_parent()
	if not parent:
		return

	var width = parent.size.x
	var height = parent.size.y
	var color = parent.bg_color

	# Slanted shape: [0,0], [width, 0], [width - 40, height], [0, height]
	var points = PackedVector2Array([
		Vector2(0, 0),
		Vector2(width, 0),
		Vector2(width - 40, height),
		Vector2(0, height)
	])

	draw_colored_polygon(points, color)

extends Node2D

@export var color: Color = Color(0.2, 0.2, 0.2, 0.9)

func _draw():
	var parent = get_parent()
	if not parent:
		return

	var width = parent.size.x
	var height = parent.size.y

	# Slanted shape: [0,0], [width, 0], [width - 40, height], [0, height]
	var points = PackedVector2Array([
		Vector2(0, 0),
		Vector2(width, 0),
		Vector2(width - 40, height),
		Vector2(0, height)
	])

	draw_colored_polygon(points, color)

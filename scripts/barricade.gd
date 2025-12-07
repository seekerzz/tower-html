extends StaticBody2D

class_name Barricade

var hp: float = 100.0
var max_hp: float = 100.0
var type: String = "wood"

func initialize(_type: String, start: Vector2, end: Vector2):
	type = _type

	# Create shape
	var shape = SegmentShape2D.new()
	shape.a = start - position # Local coords
	shape.b = end - position

	var collision = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	# Visual
	var line = Line2D.new()
	line.points = [start - position, end - position]
	line.width = 5.0
	line.default_color = Color.SADDLE_BROWN
	add_child(line)

func take_damage(amount: float):
	hp -= amount
	if hp <= 0:
		queue_free()

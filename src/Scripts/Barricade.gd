extends StaticBody2D

var hp: float
var max_hp: float
var type: String
var props: Dictionary

@onready var collision_shape = $CollisionShape2D
@onready var line_2d = $Line2D

func init(p1: Vector2, p2: Vector2, type_key: String):
	type = type_key
	if Constants.BARRICADE_TYPES.has(type_key):
		props = Constants.BARRICADE_TYPES[type_key]
		max_hp = props.get("hp", 100)
		hp = max_hp

		# Setup Visuals
		line_2d.points = [p1, p2]
		line_2d.width = props.get("width", 5)
		line_2d.default_color = props.get("color", Color.WHITE)

		# Setup Physics
		var segment = SegmentShape2D.new()
		segment.a = p1
		segment.b = p2
		collision_shape.shape = segment

		# Set collision layer/mask if needed (default is 1)
		# Usually walls are on a specific layer, but for now default is fine.
	else:
		push_error("Invalid barricade type: " + type_key)

func _draw():
	if hp < max_hp and line_2d.points.size() >= 2:
		var p1 = line_2d.points[0]
		var p2 = line_2d.points[1]
		var center = (p1 + p2) / 2
		var bar_width = 40.0
		var bar_height = 5.0
		var offset = Vector2(0, -10)

		# Background (Red)
		var bg_rect = Rect2(center.x - bar_width / 2, center.y + offset.y - bar_height / 2, bar_width, bar_height)
		draw_rect(bg_rect, Color.RED)

		# Foreground (Green)
		var health_pct = clamp(hp / max_hp, 0.0, 1.0)
		var fg_width = bar_width * health_pct
		var fg_rect = Rect2(center.x - bar_width / 2, center.y + offset.y - bar_height / 2, fg_width, bar_height)
		draw_rect(fg_rect, Color.GREEN)

func take_damage(amount: float):
	hp -= amount
	queue_redraw()

	var text_pos = global_position
	if line_2d.points.size() >= 2:
		var p1 = line_2d.points[0]
		var p2 = line_2d.points[1]
		# Use to_global to ensure correct world position regardless of node hierarchy
		text_pos = to_global((p1 + p2) / 2)

	GameManager.spawn_floating_text(text_pos, str(int(amount)), Color.RED)
	if hp <= 0:
		queue_free()

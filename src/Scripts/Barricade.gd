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

func take_damage(amount: float):
	hp -= amount
	GameManager.spawn_floating_text(global_position, str(int(amount)), Color.RED)
	if hp <= 0:
		queue_free()

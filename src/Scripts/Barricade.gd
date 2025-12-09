extends StaticBody2D

var hp: float
var max_hp: float
var type: String
var props: Dictionary

@onready var collision_shape = $CollisionShape2D

# Changed init to accept grid position or world position instead of line points
func init(pos: Vector2, type_key: String):
	type = type_key
	position = pos

	if Constants.BARRICADE_TYPES.has(type_key):
		props = Constants.BARRICADE_TYPES[type_key]
		max_hp = props.get("hp", 100)
		hp = max_hp

		# Setup Visuals - Block style
		var color = props.get("color", Color.WHITE)
		var size = Vector2(50, 50) # Slightly smaller than 60x60 tile

		# Create a visual representation (ColorRect)
		var vis = ColorRect.new()
		vis.size = size
		vis.position = -size / 2 # Center it
		vis.color = color
		add_child(vis)

		# Setup Physics - Block style
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = size
		collision_shape.shape = rect_shape

	else:
		push_error("Invalid barricade type: " + type_key)

func take_damage(amount: float):
	hp -= amount
	GameManager.spawn_floating_text(global_position, str(int(amount)), Color.RED)
	if hp <= 0:
		queue_free()

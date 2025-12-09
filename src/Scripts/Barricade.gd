extends StaticBody2D

var hp: float
var max_hp: float
var type: String
var props: Dictionary

@onready var collision_shape = $CollisionShape2D
# @onready var line_2d = $Line2D # Deprecated
var visual_rect: ColorRect = null

func init(grid_pos: Vector2i, type_key: String):
	type = type_key
	if Constants.BARRICADE_TYPES.has(type_key):
		props = Constants.BARRICADE_TYPES[type_key]
		max_hp = props.get("hp", 100)
		hp = max_hp

		var tile_size = Constants.TILE_SIZE
		var offset = Vector2(-tile_size/2.0, -tile_size/2.0)

		# Setup Visuals (Create ColorRect if not present, or use existing logic if I could change Scene)
		# Since we are code-modifying an existing node structure which expects Line2D,
		# we should probably add a ColorRect programmatically or repurpose.
		# I will add a ColorRect programmatically.

		visual_rect = ColorRect.new()
		visual_rect.size = Vector2(tile_size, tile_size)
		visual_rect.position = offset
		visual_rect.color = props.get("color", Color.WHITE)
		add_child(visual_rect)

		# Hide Line2D if it exists
		if has_node("Line2D"):
			$Line2D.visible = false

		# Setup Physics
		var rect = RectangleShape2D.new()
		rect.size = Vector2(tile_size, tile_size)
		collision_shape.shape = rect
	else:
		push_error("Invalid barricade type: " + type_key)

func take_damage(amount: float):
	hp -= amount
	GameManager.spawn_floating_text(global_position, str(int(amount)), Color.RED)
	if hp <= 0:
		queue_free()

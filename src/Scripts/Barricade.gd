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

		# Set collision layer/mask based on solidity
		var is_solid = props.get("is_solid", true)
		if is_solid:
			# Block enemies (Layer 1 is default)
			collision_layer = 1
		else:
			# Allow enemies to pass but detect interaction.
			# We'll disable layer 1 (StaticBody) so it doesn't physically block.
			# But we might want it to be detectable by Area2D.
			# If Enemy is Area2D, it monitors overlaps.
			# If Enemy uses move_and_slide, it would collide with StaticBody unless we change layers.
			# Enemy.gd moves manually: position += ...
			# Enemy.gd uses RayCast2D to check for blocking walls.
			# To prevent RayCast from "seeing" this as a wall, we can change its layer,
			# OR the Enemy raycast logic can ignore it based on "is_solid" property check (which I will implement in Enemy.gd).
			# However, "get_overlapping_bodies()" in Enemy needs to find it for trap effects.
			# So we keep it on a layer that Area2D detects, or just keep it as is and rely on logic.
			# Requirement says: "set collision layer to Area2D or disable physical collision, only keep detection"

			# If I disable layer 1, Enemy's raycast (mask=1) won't see it -> Good for movement.
			# But Enemy's get_overlapping_bodies() (mask=1 by default) also won't see it -> Bad for trap logic.

			# Solution: Put traps on Layer 2.
			# Enemy RayCast: Mask 1 (Walls).
			# Enemy Area2D: Mask 1 + 2 (Walls + Traps).

			# Let's try to set layer to 2 (Value 2, Bit 1).
			collision_layer = 2
			pass
	else:
		push_error("Invalid barricade type: " + type_key)

func _process(delta):
	if props and props.get("duration"):
		var duration = props.get("duration")
		var damage_per_sec = max_hp / duration
		take_damage(damage_per_sec * delta)

func take_damage(amount: float):
	hp -= amount
	GameManager.spawn_floating_text(global_position, str(int(amount)), Color.RED)
	if hp <= 0:
		queue_free()

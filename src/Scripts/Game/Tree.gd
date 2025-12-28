extends Node2D

func setup(width_in_tiles: int):
	var config = Constants.ENVIRONMENT_CONFIG
	var texture_path = config["tree_tile_set"]
	var columns = config["tree_columns"]

	# Load texture
	if not ResourceLoader.exists(texture_path):
		print("Error: Tree texture not found: ", texture_path)
		return

	var texture = load(texture_path)
	$Sprite2D.texture = texture

	var texture_width = texture.get_width()
	var texture_height = texture.get_height()

	# Handle division by zero if texture is invalid or columns is 0
	if columns <= 0:
		columns = 1
	var frame_width = texture_width / float(columns)
	if frame_width == 0:
		frame_width = 1.0

	# Set up sprite frame
	$Sprite2D.hframes = columns
	$Sprite2D.vframes = config.get("tree_rows", 1)
	$Sprite2D.frame = randi() % columns

	# Calculate Scale
	var base_scale = (Constants.TILE_SIZE * width_in_tiles) / frame_width
	# Slight random variation in scale for variety
	var final_scale = base_scale * randf_range(0.9, 1.0)

	scale = Vector2(final_scale, final_scale)

	# Alignment
	# We want the bottom of the sprite to be near (0,0) for Y-sorting
	var frame_height = texture_height / float($Sprite2D.vframes)
	$Sprite2D.position.y = -frame_height / 2.0

	# Random flip
	if randf() > 0.5:
		$Sprite2D.flip_h = true

	# Dynamic Collider Sizing
	# The collider needs to match the logical size in tiles * TILE_SIZE.
	# Since we scaled the Node2D, we need to be careful.
	# If we set the shape size to (width_in_tiles * TILE_SIZE), it will ALSO be scaled by `scale`.
	# So the actual world size would be (width * TILE * scale).
	# However, usually we want the collider to represent the logical grid area, so maybe we should unscale it?
	# Or, if the tree visuals are scaled, the collider should probably match the visual size?
	# Requirement: "make it equal to size_in_tiles * Constants.TILE_SIZE"
	# If I set the shape size to `size_in_tiles * Constants.TILE_SIZE` and the parent is scaled, it might be too big or small depending on scale.
	# But wait, `final_scale` is calculated to make the sprite width approx `width_in_tiles * TILE_SIZE`.
	# So if I set the shape width to `frame_width`, then `frame_width * final_scale` ~= `width_in_tiles * TILE_SIZE`.
	# But the requirement says "adjust CollisionShape2D rect size ... equal to size_in_tiles * Constants.TILE_SIZE".
	# If I set shape.size = Vector2(w * TILE, w * TILE), then with scale applied, it becomes huge.
	# Let's assume the collider should be set such that *after* scale it matches, OR we shouldn't scale the whole Node2D, only the Sprite.
	# The current code scales `self` (Node2D).

	# Let's change scaling to apply only to Sprite2D to avoid messing with physics scale if possible,
	# OR compensate in the shape size.
	# Given the previous code `scale = Vector2(...)`, it scales the whole node.
	# If I change that, it might break other things.
	# Let's keep scaling the whole node, but calculate the shape size inversely?
	# Or maybe the requirement implies the *result* size.
	# If the tree takes up 2 tiles, the collider should be 120x120 pixels in world space?
	# If `scale` is approx 1 (if sprite is high res), then it's fine.
	# But `base_scale` makes the sprite fit the tiles.

	# Let's apply scale only to Sprite2D so that the Tree node itself remains 1.0 scale.
	# This makes logic easier for Colliders.
	scale = Vector2.ONE
	$Sprite2D.scale = Vector2(final_scale, final_scale)

	var collider_size = width_in_tiles * Constants.TILE_SIZE
	var shape = RectangleShape2D.new()
	shape.size = Vector2(collider_size, collider_size)

	if has_node("Area2D/CollisionShape2D"):
		$Area2D/CollisionShape2D.shape = shape

	# Remove hardcoded z_index = 200 (It is removed by omission)

func play_leaf_fx():
	pass

extends Node2D

var visual_size: Vector2 = Vector2.ZERO

func setup(target_pixel_size: float):
	var config = Constants.ENVIRONMENT_CONFIG
	var texture_path = config["tree_tile_set"]
	var columns = config.get("tree_columns", 1)
	var rows = config.get("tree_rows", 1)

	# Load texture
	if not ResourceLoader.exists(texture_path):
		print("Error: Tree texture not found: ", texture_path)
		return

	var texture = load(texture_path)
	$Sprite2D.texture = texture

	var texture_width = texture.get_width()
	var texture_height = texture.get_height()

	if columns <= 0: columns = 1
	if rows <= 0: rows = 1

	var frame_width = texture_width / float(columns)
	var frame_height = texture_height / float(rows)

	# Set up sprite frame
	$Sprite2D.hframes = columns
	$Sprite2D.vframes = rows
	$Sprite2D.frame = 0 # Fixed to 0 (remove random selection)

	# Calculate Scale to match target_pixel_size (based on width)
	# Requirement: "Equal proportion, W=H" for the logical bounds, but we maintain aspect ratio for the sprite.
	var scale_factor = target_pixel_size / frame_width
	scale = Vector2(scale_factor, scale_factor)

	visual_size = Vector2(frame_width * scale_factor, frame_height * scale_factor)

	# Alignment: Bottom of sprite at (0,0)
	$Sprite2D.position.y = -frame_height / 2.0

	# Note: Z-Index is handled by GridManager

func get_actual_rect() -> Rect2:
	# Returns the global bounding box of the visual sprite
	# (0,0) of this node is the bottom-center of the tree.
	var half_w = visual_size.x / 2.0
	var h = visual_size.y

	# Global position is the anchor (bottom-center)
	# Top-Left is (pos.x - half_w, pos.y - h)
	var top_left = global_position + Vector2(-half_w, -h)
	return Rect2(top_left, visual_size)

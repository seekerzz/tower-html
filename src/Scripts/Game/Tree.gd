extends Node2D

var actual_size: Vector2 = Vector2.ZERO

func setup(width_in_tiles: float):
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

	# Handle division by zero
	if columns <= 0:
		columns = 1
	var frame_width = texture_width / float(columns)
	if frame_width == 0:
		frame_width = 1.0

	# Set up sprite frame
	$Sprite2D.hframes = columns
	$Sprite2D.vframes = config.get("tree_rows", 1)
	$Sprite2D.frame = 0 # No random frame selection

	# Calculate Scale (Uniform)
	# Target width W = TILE_SIZE * width_in_tiles
	# We want Uniform scaling, so scale.x = scale.y
	# We base it on width to fit the grid slots
	var target_pixel_width = Constants.TILE_SIZE * width_in_tiles
	var scale_factor = target_pixel_width / frame_width

	scale = Vector2(scale_factor, scale_factor)

	# Calculate actual size (W = H based on requirements for logic, but visual is what it is)
	# Requirement: "Trees considered as W x H rectangle... (Uniform, W=H)"
	# If the requirement implies the *Entity* is square, we'll use target_pixel_width for both dimensions in logic.
	# The sprite might be rectangular, but we scale it uniformly.
	# We will store the Logical Size for the Overlap check.
	actual_size = Vector2(target_pixel_width, target_pixel_width)

	# Alignment
	var frame_height = texture_height / float($Sprite2D.vframes)

	# Move sprite up so its bottom is at 0 (Anchor point at bottom center of the tree logic)
	$Sprite2D.position.y = -frame_height / 2.0

	# Default Z-index (will be overridden by manager)
	z_index = 0

func get_actual_rect() -> Rect2:
	# Returns the Global Bounding Box for the Logic (Square)
	# Centered at global_position?
	# Tree.gd is a Node2D. Position is usually center of the tile width, bottom of the tile.
	# If we treat it as a square WxH.
	# The sprite is anchored at (0, -H/2).
	# Logic box should probably roughly match the sprite's visual bulk.
	# Let's assume the rect is centered on (0, -actual_size.y / 2).

	var half_size = actual_size / 2.0
	# Local Rect relative to tree position
	# Visual sprite is at (0, -frame_h/2).
	# We want the rect to be useful for "Overlap".
	# Let's position the logical rect at ( -W/2, -H ). So it sits on the pivot.
	var top_left_local = Vector2(-half_size.x, -actual_size.y)

	# Global
	var global_pos = global_position
	return Rect2(global_pos + top_left_local, actual_size)

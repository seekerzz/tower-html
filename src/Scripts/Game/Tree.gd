extends Node2D

var actual_width: float = 0.0
var actual_height: float = 0.0

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

	var rows = config.get("tree_rows", 1)
	if rows <= 0: rows = 1
	var frame_height = texture_height / float(rows)

	# Set up sprite frame
	$Sprite2D.hframes = columns
	$Sprite2D.vframes = rows
	$Sprite2D.frame = randi() % columns

	# Calculate Scale
	# base_scale = (Constants.TILE_SIZE * width_in_tiles) / (texture_width / columns)
	var base_scale = (Constants.TILE_SIZE * width_in_tiles) / frame_width
	var final_scale = base_scale * randf_range(0.9, 1.0)

	scale = Vector2(final_scale, final_scale)

	actual_width = frame_width * final_scale
	actual_height = frame_height * final_scale

	# Alignment
	# Sprite2D bottom aligned to origin.
	# If centered=true (default), origin is center of sprite.
	# We want bottom of sprite at (0,0) of the Tree node.

	# Move sprite up by half its height so its bottom is at 0
	$Sprite2D.position.y = -frame_height / 2.0

	# Random flip
	if randf() > 0.5:
		$Sprite2D.flip_h = true

	# Z-Index will be set by GridManager based on Y position
	# But we can also update it dynamically if position changes
	z_index = int(position.y)

func get_actual_size() -> Vector2:
	return Vector2(actual_width, actual_height)

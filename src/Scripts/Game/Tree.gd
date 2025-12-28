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
	# base_scale = (Constants.TILE_SIZE * width_in_tiles) / (texture_width / columns)
	var base_scale = (Constants.TILE_SIZE * width_in_tiles) / frame_width
	var final_scale = base_scale * randf_range(0.9, 1.1)

	scale = Vector2(final_scale, final_scale)

	# Alignment
	# Sprite2D bottom aligned to origin.
	# If centered=true (default), origin is center of sprite.
	# We want bottom of sprite at (0,0) of the Tree node.
	# The height of the sprite is texture_height / rows
	var frame_height = texture_height / float($Sprite2D.vframes)

	# Move sprite up by half its height so its bottom is at 0
	$Sprite2D.position.y = -frame_height / 2.0

	# Random flip
	if randf() > 0.5:
		$Sprite2D.flip_h = true

	z_index = 200

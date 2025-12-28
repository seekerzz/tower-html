extends Node2D

var _scaled_size: Vector2 = Vector2.ZERO

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

	# Calculate and store actual pixel size
	_scaled_size = Vector2(frame_width * final_scale, frame_height * final_scale)

	# Alignment
	# Sprite2D bottom aligned to origin.
	# If centered=true (default), origin is center of sprite.
	# We want bottom of sprite at (0,0) of the Tree node.
	# The height of the sprite is texture_height / rows

	# Move sprite up by half its height so its bottom is at 0
	$Sprite2D.position.y = -frame_height / 2.0

	# Random flip
	if randf() > 0.5:
		$Sprite2D.flip_h = true

	update_z_index()

func get_pixel_size() -> Vector2:
	return _scaled_size

func update_z_index():
	# Visual intent: "Visual position lower (bottom of screen) occludes position upper (top of screen)"
	# In Godot (Y-Down): Bottom is Large Y. Top is Small Y.
	# So Large Y should have Higher Z-Index.
	# The prompt requested "Inverse Logic" (Small Y -> Large Z) likely assuming Y-Up coordinates.
	# To achieve the correct visual result in Godot, we use Standard Logic (Large Y -> Large Z).
	z_index = int(global_position.y)

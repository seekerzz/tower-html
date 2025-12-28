extends Node2D

var width_in_tiles: int = 1

func setup(w: int):
	width_in_tiles = w
	var sprite = $Sprite2D
	if not sprite:
		return

	# Load texture from Constants
	var texture_path = Constants.ENVIRONMENT_CONFIG.get("tree_texture", "")
	if texture_path and ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)

	var columns = Constants.ENVIRONMENT_CONFIG.get("tree_columns", 1)
	sprite.hframes = columns

	sprite.frame = randi() % columns

	var texture_width = sprite.texture.get_width() if sprite.texture else 60
	var frame_width = texture_width / float(columns)

	var base_scale = (Constants.TILE_SIZE * width_in_tiles) / frame_width
	var final_scale = base_scale * randf_range(0.9, 1.0)

	sprite.scale = Vector2(final_scale, final_scale)

	var frame_height = sprite.texture.get_height() if sprite.texture else 60
	sprite.offset.y = -frame_height / 2.0

	# Random flip
	if randf() < 0.5:
		sprite.flip_h = true

	z_index = 200

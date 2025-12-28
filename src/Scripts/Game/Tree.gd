extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

func setup(texture: Texture2D, region_rect: Rect2):
	if not sprite:
		# In case setup is called before ready, though usually called after instantiate
		sprite = $Sprite2D

	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region_rect

	# Auto-adjust scale based on TILE_SIZE and tree width
	# The goal is that the tree fits somewhat within the tile width or is proportional to it.
	# The prompt says: base_scale = Constants.TILE_SIZE / region_rect.size.x
	var base_scale = Constants.TILE_SIZE / region_rect.size.x

	# Random variation
	# We use the config scale_range from Constants.ENVIRONMENT_CONFIG["default"]
	# (or pass config, but simpler to use default or passed args if we wanted full generality)
	# The prompt implies we should use Constants or receive it.
	# "final scale = base_scale * randf_range(0.9, 1.0)"
	# The 0.9 and 1.0 are in Constants.ENVIRONMENT_CONFIG["default"]["scale_range"] (as Vector2)

	var config = Constants.get_theme_config("default")
	var range_min = config.scale_range.x
	var range_max = config.scale_range.y

	var random_factor = randf_range(range_min, range_max)
	var final_scale = base_scale * random_factor

	scale = Vector2(final_scale, final_scale)

	# Ensure sprite is centered and offset correctly.
	# Prompt: "Sprite2D centered = true. Modify offset or position so bottom aligns with (0,0)"
	sprite.centered = true
	# If centered is true, the center of the sprite is at (0,0).
	# Top is -h/2, Bottom is h/2.
	# To align bottom to (0,0), we need to move sprite up by h/2.
	# So position.y = -region_rect.size.y / 2
	sprite.position.y = -region_rect.size.y / 2

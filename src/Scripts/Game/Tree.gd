extends Node2D

@onready var sprite = $Sprite2D

func setup(texture: Texture2D, region_rect: Rect2, grid_tile_size: float = 60.0):
	if not sprite:
		# If setup is called before ready, wait for ready
		await ready

	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region_rect
	sprite.centered = true

	# Adaptive scaling
	# base_scale = TILE_SIZE / region_rect.size.x
	var base_scale = grid_tile_size / region_rect.size.x

	# Randomization
	# Constants might not be available here directly if they are static or autoloader?
	# Actually Constants is likely an Autoload or a class_name.
	# Assuming Constants is an Autoload or global class.
	# The plan said usage of Constants.ENVIRONMENT_CONFIG is in GridManager mainly,
	# but for random scale range, the prompt said:
	# "Final scale value = base_scale * randf_range(0.9, 1.0)"
	# and "Use Constants.ENVIRONMENT_CONFIG['scale_range']" implicitly or explicitly?
	# "scale_range: Vector2(0.9, 1.0)" in Constants.

	# Accessing Constants.ENVIRONMENT_CONFIG
	# Since Constants.gd extends Node, it is likely an Autoload named Constants.
	var scale_range = Constants.ENVIRONMENT_CONFIG["scale_range"]
	var random_factor = randf_range(scale_range.x, scale_range.y)
	var final_scale = base_scale * random_factor

	scale = Vector2(final_scale, final_scale)

	# Alignment: Visual bottom alignment to (0,0)
	# Sprite centered means center is at (0,0).
	# Bottom of sprite is at height/2.
	# We want bottom of sprite to be at 0.
	# So we move sprite up by height/2.
	# region_rect.size.y is the height in pixels (unscaled).
	# Since we are scaling the Node2D, the local offset should be in unscaled pixels.

	sprite.position.y = -region_rect.size.y / 2.0

	# Print for verification
	print("Tree setup: Scale=", final_scale, " (Base: ", base_scale, ")")

func set_flip_h(value: bool):
	if not sprite:
		await ready
	sprite.flip_h = value

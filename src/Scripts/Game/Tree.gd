extends Node2D

var actual_w: float = 0.0
var actual_h: float = 0.0

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

	var vframes = config.get("tree_rows", 1)
	if vframes <= 0:
		vframes = 1
	var frame_height = texture_height / float(vframes)

	# Set up sprite frame
	$Sprite2D.hframes = columns
	$Sprite2D.vframes = vframes
	$Sprite2D.frame = randi() % columns

	# Calculate Scale
	# Current logic: Scale based on width_in_tiles.
	# width_in_tiles is usually 2, 3, etc. for "Grid Units".
	# The refactor says "Equal proportion scaling".
	var base_scale = (Constants.TILE_SIZE * width_in_tiles) / frame_width

	# Apply slight randomness but keep Aspect Ratio
	var final_scale = base_scale * randf_range(0.9, 1.0)

	scale = Vector2(final_scale, final_scale)

	# Calculate Actual Dimensions (W, H)
	actual_w = frame_width * final_scale
	actual_h = frame_height * final_scale

	# Alignment
	# Sprite2D bottom aligned to origin.
	# The origin of the Tree node (0,0) will be the "Root".
	# Sprite2D is centered by default.
	# We want the bottom of the sprite to be at (0,0).
	# Sprite Height is frame_height. Center is at frame_height/2.
	# So we move it up by frame_height/2.
	$Sprite2D.position.y = -frame_height / 2.0

	# Random flip
	if randf() > 0.5:
		$Sprite2D.flip_h = true

	# Z-Index Management
	# Handled in _process or manually set after position is determined.
	# However, Tree.gd doesn't know its final position in setup().
	# We will rely on GridManager or a self-update to set z_index.
	# For static trees, we can set it once.

func _ready():
	# If position is already set when _ready is called
	update_z_index()

func update_z_index():
	# Strictly enforce "Y axis value smaller, Z-Index higher" logic?
	# NO, prompt says: "If project uses Godot default Y axis (downward growth), please ensure logic maps correctly to achieve 'below covers above'."
	# In Godot Y-Down: Below (Larger Y) covers Above (Smaller Y).
	# So Larger Y -> Higher Z-Index.
	z_index = int(position.y)

extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

# Configurable properties
@export var sway_intensity: float = 10.0
@export var sway_speed: float = 1.0
@export var parallax_factor: float = 0.02
@export var outline_width: float = 1.0
@export var outline_color: Color = Color(0.12, 0.12, 0.12, 1.0)

# Random seeds
var sway_phase: float = 0.0
var _last_zoom: Vector2 = Vector2(-1, -1)

func _ready():
	# Randomize sway phase
	sway_phase = randf_range(0.0, 6.28)

	# Apply Instance Uniforms
	# Note: In Godot 4.x, instance uniforms are set on the GeometryInstance or the shader via specific methods if configured as instance uniforms.
	# The shader uses "instance uniform".
	# In GDScript, we set them on the node that renders the mesh/sprite.

	# Wait, Sprite2D inherits from Node2D -> CanvasItem.
	# Instance Uniforms (per-instance) in 2D require passing them via the material if they are just regular uniforms,
	# OR if using the "instance uniform" keyword in shader, we assume Godot handles them via internal batching or we set them on the node.
	# Actually, for "instance uniform", we normally set_instance_shader_parameter on the CanvasItem.

	sprite.set_instance_shader_parameter("sway_phase", sway_phase)
	sprite.set_instance_shader_parameter("parallax_factor", parallax_factor)
	sprite.set_instance_shader_parameter("sway_intensity", sway_intensity)
	sprite.set_instance_shader_parameter("sway_speed", sway_speed)
	sprite.set_instance_shader_parameter("outline_color", outline_color)

	# Set non-instance uniforms on the material (shared)
	var mat = sprite.material as ShaderMaterial
	if mat:
		# outline_width is still a regular uniform (shared)
		mat.set_shader_parameter("outline_width", outline_width)

	# Initial update
	_update_global_scale()

func setup_visuals(texture: Texture2D, hframes: int, vframes: int, frame_idx: int, flip_h: bool, scale_val: float):
	sprite.texture = texture
	sprite.hframes = hframes
	sprite.vframes = vframes
	sprite.frame = frame_idx
	sprite.flip_h = flip_h

	# Apply scale to the root Node2D or the Sprite?
	# If we apply to Node2D, everything scales.
	self.scale = Vector2(scale_val, scale_val)

	# We need to pass this scale to the shader for outline compensation.
	# Since this node is scaled, the sprite inherits it.
	_update_global_scale(true)

func _update_global_scale(force: bool = false):
	if not is_inside_tree(): return

	var zoom = Vector2(1,1)
	if GameManager.grid_manager and GameManager.grid_manager.get_viewport():
		var cam = GameManager.grid_manager.get_viewport().get_camera_2d()
		if cam:
			zoom = cam.zoom

	if not force and zoom.is_equal_approx(_last_zoom):
		return

	_last_zoom = zoom

	var total_scale = global_scale * zoom
	sprite.set_instance_shader_parameter("global_scale", total_scale)

func _process(_delta):
	# Camera global pos is updated by GridManager to avoid redundant updates.
	# We just need to ensure scale is updated if zoom changes.

	# Optimization: Only update if zoom changed
	_update_global_scale()

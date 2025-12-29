extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

# Configurable properties
@export var sway_intensity: float = 10.0
@export var sway_speed: float = 1.0
@export var parallax_factor: float = 0.02
@export var outline_width: float = 1.0
@export var outline_color: Color = Color(0.12, 0.12, 0.12, 1.0)

var flexibility: float = 1.8

# Random seeds
var sway_phase: float = 0.0
var _last_zoom: Vector2 = Vector2.ONE
var _impact_tween: Tween

func _ready():
	# Connect to impact signal
	if GameManager:
		GameManager.world_impact.connect(_on_world_impact)

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
	sprite.set_instance_shader_parameter("impact_offset", Vector2.ZERO)

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

	# Adjust flexibility based on "Flower" vs "Tree" (heuristic: flowers are smaller/set via setup)
	# Since this script is mainly for decorations spawned via setup_visuals (plants), we assume high flexibility.
	# But if we were a tree, we'd want lower flexibility.
	# If scale is large, maybe less flexible?
	# Heuristic: Plants/Flowers (flexibility = 1.8), Trees (flexibility = 0.5)
	# For now, since EnvironmentDecoration.tscn is mostly plants, we default to 1.8.
	# If we use this script for trees, we need to set it.

	# We need to pass this scale to the shader for outline compensation.
	# Since this node is scaled, the sprite inherits it.
	_update_global_scale()

func _on_world_impact(direction: Vector2, strength: float):
	if _impact_tween and _impact_tween.is_valid():
		_impact_tween.kill()

	_impact_tween = create_tween()

	# Target offset: direction * strength * flexibility
	# Note: strength is normalized (~1.0). direction is normalized.
	# impact_offset in shader is added to VERTEX.xy * dist_from_root.
	# If dist_from_root is ~10-20 pixels.
	# We want a visible sway.
	# If we pass, say, Vector2(1,0), then top moves 1 * 20 = 20 pixels. That's a lot.
	# Maybe scale down?
	# strength is usually 0.5 to 3.0.
	# flexibility 0.5 to 1.8.
	# Let's say strength=1, flex=1. Offset = 1.
	# Shift = 1 * 20 = 20px.
	# Maybe we want small shift. 0.1?
	# Let's scale by 0.1 factor to keep it subtle.
	var target_offset = direction * strength * flexibility * 0.1

	# Phase 1: Impact (Fast)
	_impact_tween.tween_method(
		func(val): sprite.set_instance_shader_parameter("impact_offset", val),
		Vector2.ZERO,
		target_offset,
		0.1
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Phase 2: Recovery (Elastic)
	_impact_tween.tween_method(
		func(val): sprite.set_instance_shader_parameter("impact_offset", val),
		target_offset,
		Vector2.ZERO,
		1.5 # Duration
	).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _update_global_scale():
	if not is_inside_tree(): return
	var zoom = Vector2(1,1)
	if GameManager.grid_manager and GameManager.grid_manager.get_viewport():
		var cam = GameManager.grid_manager.get_viewport().get_camera_2d()
		if cam:
			zoom = cam.zoom

	var total_scale = global_scale * zoom
	sprite.set_instance_shader_parameter("global_scale", total_scale)

func _process(_delta):
	# Camera global pos is updated by GridManager to avoid redundant updates.
	# We just need to ensure scale is updated if zoom changes.

	if GameManager.grid_manager and GameManager.grid_manager.get_viewport():
		var cam = GameManager.grid_manager.get_viewport().get_camera_2d()
		if cam and cam.zoom != _last_zoom:
			_last_zoom = cam.zoom
			_update_global_scale()

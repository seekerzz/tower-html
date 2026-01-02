extends Area2D

var type: String
var props: Dictionary

@onready var collision_shape = $CollisionShape2D
# @onready var line_2d = $Line2D # Deprecated
var visual_rect: ColorRect = null

var trap_timer: float = 0.0
var is_triggered: bool = false
var flash_timer: float = 0.0

func init(grid_pos: Vector2i, type_key: String):
	type = type_key
	if Constants.BARRICADE_TYPES.has(type_key):
		props = Constants.BARRICADE_TYPES[type_key]

		var tile_size = Constants.TILE_SIZE
		var offset = Vector2(-tile_size/2.0, -tile_size/2.0)

		# Setup Visuals
		var label = Label.new()
		label.name = "Label"
		label.text = props.get("icon", "?")
		label.add_theme_font_size_override("font_size", 32)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(tile_size, tile_size)
		label.position = offset
		add_child(label)

		# Setup Drag Handler
		var drag_handler = Control.new()
		var script = load("res://src/Scripts/UI/TrapDragHandler.gd")
		if script:
			drag_handler.set_script(script)
			add_child(drag_handler)
			drag_handler.setup(self)

		# Hide Line2D if it exists
		if has_node("Line2D"):
			$Line2D.visible = false

		# Setup Physics
		var rect = RectangleShape2D.new()
		rect.size = Vector2(tile_size, tile_size)
		collision_shape.shape = rect

		# Collision Settings
		# Detect Enemies (Layer 2)
		collision_layer = 4 # Trap Layer
		collision_mask = 2 # Enemy Layer
		monitoring = true
		monitorable = true

		body_entered.connect(_on_body_entered)

		# Snowball Trap Logic: Start Timer
		if props.get("type") == "trap_freeze":
			trap_timer = 3.0
			GameManager.spawn_floating_text(global_position, "3...", Color.WHITE)

	else:
		push_error("Invalid barricade type: " + type_key)

func update_level(new_level: int):
	if !props: return
	# Re-initialize or scale properties based on level if data supports it
	# Assuming simple scaling for now since data doesn't have levels for barricades yet
	# But following prompt: "Re-initialize trap properties based on Constants.BARRICADE_TYPES level data"
	# If BARRICADE_TYPES has no level data, we might assume Unit level scaling logic or just keep base.

	# Current BARRICADE_TYPES structure is flat.
	# We can add a simple multiplier based on level:
	var strength = props.get("strength", 0)
	var new_strength = strength * (1.0 + (new_level - 1) * 0.5)

	# If we stored this in a variable, update it.
	# props is a reference to CONSTANT dict usually, so we shouldn't modify it directly if it's shared.
	# But here we are reading.
	# Barricade logic uses props directly.
	# To support leveling, we should probably clone props and modify locally.

	if props == Constants.BARRICADE_TYPES[type]:
		props = props.duplicate()

	props["strength"] = new_strength

	# Visual update if needed (e.g. size or color intensity)
	var label = get_node_or_null("Label")
	if label:
		if new_level > 1:
			label.modulate = Color(1.2, 1.2, 1.2) # Brighter
		else:
			label.modulate = Color.WHITE

func _process(delta):
	if !props: return

	# Continuous Effect Application (moved from Enemy.check_traps)
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.has_method("handle_environmental_impact"):
			body.handle_environmental_impact(self)

	# Snowball Trap Logic
	if props.get("type") == "trap_freeze" and !is_triggered:
		trap_timer -= delta
		flash_timer += delta

		# Visual Feedback: Flashing
		# Frequency increases as timer decreases
		var frequency = 5.0 + (3.0 - trap_timer) * 5.0
		var alpha = 0.5 + 0.5 * sin(flash_timer * frequency)
		modulate.a = alpha

		if trap_timer <= 0:
			trigger_freeze_explosion()

func trigger_freeze_explosion():
	is_triggered = true
	GameManager.spawn_floating_text(global_position, "Freeze!", Color.CYAN)

	# Visual Effect
	spawn_splash_effect(global_position)

	# Logic: Freeze enemies in 3x3 range
	var center_pos = global_position
	var range_sq = (Constants.TILE_SIZE * 1.5) ** 2

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.global_position.distance_squared_to(center_pos) <= range_sq:
			if enemy.has_method("apply_freeze"):
				enemy.apply_freeze(2.0)
			elif enemy.has_method("apply_stun"):
				enemy.apply_stun(2.0)

	if GameManager.grid_manager:
		GameManager.grid_manager.remove_obstacle(self)
	queue_free()

func spawn_splash_effect(pos: Vector2):
	var color = props.get("color", Color.WHITE)
	var effect = load("res://src/Scripts/Effects/SlashEffect.gd").new()
	get_parent().add_child(effect)
	effect.global_position = pos
	effect.configure("cross", color)
	effect.scale = Vector2(2, 2)
	effect.play()

func _on_body_entered(body):
	if props.get("type") == "reflect":
		if body.has_method("handle_environmental_impact"):
			body.handle_environmental_impact(self)

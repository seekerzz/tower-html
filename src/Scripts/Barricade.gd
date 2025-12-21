extends StaticBody2D

var hp: float
var max_hp: float
var type: String
var props: Dictionary

@onready var collision_shape = $CollisionShape2D
# @onready var line_2d = $Line2D # Deprecated
var visual_rect: ColorRect = null

func init(grid_pos: Vector2i, type_key: String):
	type = type_key
	if Constants.BARRICADE_TYPES.has(type_key):
		props = Constants.BARRICADE_TYPES[type_key]
		max_hp = props.get("hp", 100)
		hp = max_hp

		var tile_size = Constants.TILE_SIZE
		var offset = Vector2(-tile_size/2.0, -tile_size/2.0)

		# Setup Visuals (Create ColorRect if not present, or use existing logic if I could change Scene)
		# Since we are code-modifying an existing node structure which expects Line2D,
		# we should probably add a ColorRect programmatically or repurpose.
		# I will add a ColorRect programmatically.

		var label = Label.new()
		label.text = props.get("icon", "?")
		label.add_theme_font_size_override("font_size", 32)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(tile_size, tile_size)
		label.position = offset
		add_child(label)

		# Hide Line2D if it exists
		if has_node("Line2D"):
			$Line2D.visible = false

		# Setup Physics
		var rect = RectangleShape2D.new()
		rect.size = Vector2(tile_size, tile_size)
		collision_shape.shape = rect

		# Force collision layer to 2 (Non-blocking)
		# This ensures enemies (Layer 1 RayCast) walk through walls.
		# But enemies' Area2D (Mask 1+2) will still detect it for trap effects.
		collision_layer = 2
	else:
		push_error("Invalid barricade type: " + type_key)

	if props and props.type == "trap_freeze":
		fuse_timer = 3.0

var fuse_timer: float = 0.0

func _process(delta):
	if props and props.get("duration"):
		var duration = props.get("duration")
		var damage_per_sec = max_hp / duration
		take_damage(damage_per_sec * delta)

	if props and props.type == "trap_freeze":
		fuse_timer -= delta
		if fuse_timer <= 0:
			_explode_snowball()

func _explode_snowball():
	# Visual Effect
	GameManager.spawn_floating_text(global_position, "BOOM!", Color.CYAN)
	# Reuse SlashEffect as generic explosion
	var effect = load("res://src/Scripts/Effects/SlashEffect.gd").new()
	get_parent().add_child(effect)
	effect.global_position = global_position
	effect.configure("cross", Color.CYAN)
	effect.scale = Vector2(3, 3)
	effect.play()

	# Freeze Logic (3x3 area)
	# Check 8 neighbors + center. But simple distance check is easier.
	# 3x3 tiles is roughly 1.5 * TILE_SIZE radius, or just distance check.
	# TILE_SIZE is usually 64 or similar. Let's assume range 100.

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) <= 100.0:
			if enemy.has_method("apply_freeze"):
				enemy.apply_freeze(3.0) # Freeze for 3 seconds? Or duration?
			elif enemy.has_method("apply_stun"):
				enemy.apply_stun(3.0)

	# Destroy self
	if GameManager.grid_manager:
		GameManager.grid_manager.remove_obstacle(self)
	queue_free()

func take_damage(amount: float, source = null):
	hp -= amount
	GameManager.spawn_floating_text(global_position, str(int(amount)), Color.RED)

	if props and props.type == "reflect" and source and is_instance_valid(source):
		if source.has_method("take_damage"):
			var dmg = props.get("strength", 10.0)
			source.take_damage(dmg, self, "physical")

	if hp <= 0:
		if GameManager.grid_manager:
			GameManager.grid_manager.remove_obstacle(self)
		queue_free()

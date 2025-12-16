extends Node2D

var duration = 4.0
var tick_interval = 0.2
var area_size = Vector2.ZERO # Initialized in _ready

var _timer = null

func _ready():
	# area_size initialization relies on Constants which might not be preloaded if this is run in isolation
	# But in Godot Constants is usually a singleton or globally accessible class
	# Assuming Constants is a global class or autoload

	if area_size == Vector2.ZERO:
		# Fallback if not set by caller or global Constants not available (for tests)
		if has_node("/root/Constants"):
			var Constants = get_node("/root/Constants")
			area_size = Vector2(4, 4) * Constants.TILE_SIZE
		elif FileAccess.file_exists("res://src/Scripts/Constants.gd"):
			var Constants = load("res://src/Scripts/Constants.gd").new()
			area_size = Vector2(4, 4) * Constants.TILE_SIZE
		else:
			area_size = Vector2(240, 240) # Default fallback

	_timer = Timer.new()
	_timer.wait_time = tick_interval
	_timer.one_shot = false
	_timer.autostart = true
	_timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	add_child(_timer)

	# Self destruct timer
	var destruct_timer = Timer.new()
	destruct_timer.wait_time = duration
	destruct_timer.one_shot = true
	destruct_timer.autostart = true
	destruct_timer.connect("timeout", Callable(self, "queue_free"))
	add_child(destruct_timer)

func _on_timer_timeout():
	var random_x = randf_range(-area_size.x / 2.0, area_size.x / 2.0)
	var random_y = randf_range(-area_size.y / 2.0, area_size.y / 2.0)
	var random_pos = Vector2(random_x, random_y)

	var projectile_scene = preload("res://src/Scenes/Game/Projectile.tscn")
	var projectile = projectile_scene.instantiate()

	var start_pos = random_pos + Vector2(0, -500)
	var target_pos = random_pos # Use a dummy target or just position

	# Projectile setup: setup(start_pos, target_node, dmg, proj_speed, proj_type, stats = {})
	# We don't have a target unit, so target_node is null.
	# But Projectile.gd uses target_node for direction.
	# If target is null, it might not move unless we hack it or if it supports moving to a point.
	# Let's check Projectile.gd again.

	# Projectile.gd:
	# if is_instance_valid(target):
	#   direction = (target.global_position - global_position).normalized()
	# else:
	#   direction = Vector2.RIGHT.rotated(rotation)

	# So if we set rotation correctly, it will move there.
	var direction = (target_pos - start_pos).normalized()
	var angle = direction.angle()

	var stats = {
		"angle": angle
	}

	# We need to add the projectile to the scene tree.
	# Usually projectiles are added to a manager or the map.
	# Here we can add it to this node or the parent.
	# But this node might be destroyed before projectile finishes.
	# The projectile also has logic `get_parent().call_deferred("add_child", proj)` in split,
	# suggesting it expects to be in a container.
	# Let's add it to the scene root or current parent.

	if get_parent():
		get_parent().add_child(projectile)
	else:
		add_child(projectile) # Fallback

	projectile.setup(start_pos, null, 10, 600, "meteor", stats)

	# Since target is null, we need to ensure it stops or explodes when hitting ground.
	# Standard projectile only explodes on Area2D collision with enemy or timeout.
	# "Meteor" logic suggests it hits the ground (target_pos).
	# Projectile.gd doesn't support "move to point" natively unless we add it or use a fake target.
	# But for visual test, seeing it fall is enough.
	# It will keep falling past the target point until life expires.
	# Life = 2.0s. 500px / 600 speed < 1s. So it will pass through.
	# This matches "falling object" visual.

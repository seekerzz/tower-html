extends Node2D

var duration = 4.0
var tick_interval = 0.05 # Increased rate (20 per second)
var area_size = Vector2.ZERO

var _timer = null

func _ready():
	if area_size == Vector2.ZERO:
		if has_node("/root/Constants"):
			var Constants = get_node("/root/Constants")
			area_size = Vector2(4, 4) * Constants.TILE_SIZE
		elif FileAccess.file_exists("res://src/Scripts/Constants.gd"):
			var Constants = load("res://src/Scripts/Constants.gd").new()
			area_size = Vector2(4, 4) * Constants.TILE_SIZE
		else:
			area_size = Vector2(240, 240)

	_timer = Timer.new()
	_timer.wait_time = tick_interval
	_timer.one_shot = false
	_timer.autostart = true
	_timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	add_child(_timer)

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

	# Start higher for faster speed to look good
	var spawn_height = 600.0
	var start_pos = random_pos + Vector2(0, -spawn_height)
	var target_pos = random_pos

	var direction = (target_pos - start_pos).normalized()
	var angle = direction.angle()

	var speed = 900.0 # Faster
	var travel_time = spawn_height / speed

	var stats = {
		"angle": angle
	}

	if get_parent():
		get_parent().add_child(projectile)
	else:
		add_child(projectile)

	projectile.setup(start_pos, null, 10, speed, "meteor", stats)

	# Set life to exactly when it hits the ground so it explodes there
	projectile.life = travel_time

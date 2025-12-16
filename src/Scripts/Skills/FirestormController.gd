extends Node2D

const ProjectileScene = preload("res://src/Scenes/Game/Projectile.tscn")
const Constants = preload("res://src/Scripts/Constants.gd")

var duration: float = 4.0
var tick_interval: float = 0.2
var area_size: Vector2

func _ready():
	area_size = Vector2(4, 4) * Constants.TILE_SIZE

	var timer = Timer.new()
	timer.wait_time = tick_interval
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	timer.autostart = true
	add_child(timer)

	# Self destruct timer
	var life_timer = Timer.new()
	life_timer.wait_time = duration
	life_timer.one_shot = true
	life_timer.connect("timeout", Callable(self, "queue_free"))
	life_timer.autostart = true
	add_child(life_timer)

func _on_timer_timeout():
	var half_size = area_size / 2
	var random_x = randf_range(-half_size.x, half_size.x)
	var random_y = randf_range(-half_size.y, half_size.y)

	# Target position on the ground (relative to this controller's center)
	var target_pos = global_position + Vector2(random_x, random_y)
	# Start position in the sky
	var start_pos = target_pos + Vector2(0, -500)

	var projectile = ProjectileScene.instantiate()

	# Calculate angle pointing down (should be PI/2 or 90 degrees)
	var angle = (target_pos - start_pos).angle()

	# Calculate lifetime so it expires exactly when hitting the ground
	# Distance is 500. Let's use speed 600 for fast falling rain.
	var speed = 600.0
	var lifetime = 500.0 / speed

	projectile.setup(
		start_pos,
		null, # No specific target unit
		10.0, # Damage
		speed,
		"meteor",
		{"angle": angle}
	)

	# Override life to stop/explode at ground
	projectile.life = lifetime

	# Add to the same parent as this controller (so it persists if controller dies, or just to be in the world space)
	# If parent is null (e.g. testing), add to self (but might be deleted).
	if get_parent():
		get_parent().add_child(projectile)
	else:
		add_child(projectile)

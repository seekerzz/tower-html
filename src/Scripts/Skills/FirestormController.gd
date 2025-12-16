extends Node2D

var duration: float = 4.0
var spawn_interval: float = 0.2
var spawn_timer: float = 0.0

const TILE_SIZE = 60
const PROJECTILE_SCRIPT = preload("res://src/Scripts/Projectile.gd")

func _ready():
	pass

func _process(delta):
	duration -= delta
	if duration <= 0:
		queue_free()
		return

	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = spawn_interval
		_spawn_meteor()

func _spawn_meteor():
	# Range (-2, -2) to (2, 2) * TILE_SIZE around global_position
	var offset_x = randf_range(-2, 2) * TILE_SIZE
	var offset_y = randf_range(-2, 2) * TILE_SIZE

	var target_pos = global_position + Vector2(offset_x, offset_y)
	var start_pos = target_pos + Vector2(0, -600)

	# Instantiate Projectile
	var projectile = PROJECTILE_SCRIPT.new()

	# Setup
	# setup(start_pos, target_node, dmg, proj_speed, proj_type, stats = {})
	# Meteor falls down. Target is just the ground position?
	# We can use a dummy target node or handle movement logic differently.
	# But Projectile.gd moves towards target or direction.
	# If we set start_pos high and target_pos low, it should move there.
	# But Projectile.gd requires a target_node to home in, OR sets direction based on angle.
	# If target is null, it uses rotation.

	var angle = (target_pos - start_pos).angle()
	var speed = 600.0 # 1 second to land roughly

	var stats = {
		"angle": angle,
		"damageType": "fire",
		"pierce": 999, # Meteor hits area? Or just one spot.
		"effects": {"burn": 1.0}
	}

	projectile.setup(start_pos, null, 20.0, speed, "meteor", stats)

	# Add to Scene (MainGame or GridManager usually, but we can add to self or parent)
	# If we add to self, they disappear when controller dies (4s).
	# Usually better to add to a common container.
	get_parent().add_child(projectile)

	# Override visual for meteor if not handled in Projectile.gd
	_setup_meteor_visual(projectile)

func _setup_meteor_visual(projectile):
	# Assuming Projectile doesn't have "meteor" visual setup yet.
	# We can add it here.
	var visual = Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-10, -10), Vector2(10, -10),
		Vector2(10, 10), Vector2(-10, 10)
	])
	visual.color = Color.ORANGE_RED
	projectile.add_child(visual)

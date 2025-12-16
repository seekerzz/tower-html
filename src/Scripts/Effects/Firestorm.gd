extends Node2D

var duration: float = 4.0
var spawn_interval: float = 0.2
var timer: float = 0.0
var unit = null # Source unit
var area_size: Vector2 = Vector2(240, 240)

const PROJECTILE_SCENE = preload("res://src/Scenes/Game/Projectile.tscn")

func setup(source_unit, size: Vector2):
	unit = source_unit
	area_size = size

func _process(delta):
	duration -= delta
	if duration <= 0:
		queue_free()
		return

	timer -= delta
	if timer <= 0:
		timer = spawn_interval
		spawn_projectile()

func spawn_projectile():
	if !unit or !is_instance_valid(unit): return

	# Random position within area
	var rx = randf_range(-area_size.x/2, area_size.x/2)
	var ry = randf_range(-area_size.y/2, area_size.y/2)
	var spawn_pos = global_position + Vector2(rx, ry)

	# Create projectile
	# To simulate "falling", we might want it to start higher and move down?
	# Or just spawn at the spot and move down?
	# "Spawn in area ... type fire, vertically moving down"
	# If top-down 2D, "vertically moving down" means moving +Y.

	var proj = PROJECTILE_SCENE.instantiate()
	var stats = {
		"source": unit,
		"damageType": "fire",
		"angle": PI/2 # Pointing down (90 deg)
	}

	# Setup projectile
	# Damage? Maybe half unit damage per hit?
	var dmg = unit.damage * 0.5
	var speed = 300.0

	# Adjust spawn pos so it falls "through" the area?
	# If we want it to hit things in the area, and it moves down,
	# we should probably spawn it at the top of the area (relative to where it hits?)
	# Or just spawn it at random spot and let it travel.
	# If it travels down, it will exit the area quickly.
	# Let's assume it spawns "above" (z-axis fake) or just spawns and moves down across the map.
	# "Rain of fire" usually means spawning at random X,Y and hitting that spot.
	# If it's a projectile moving down (+Y), it acts like a wall of fire moving down.
	# Let's spawn it a bit higher so it travels through the point.

	spawn_pos.y -= 50 # Start a bit higher

	proj.setup(spawn_pos, null, dmg, speed, "fire", stats)

	# Add to game
	if unit.get_parent():
		unit.get_parent().add_child(proj)
	else:
		get_tree().root.add_child(proj)

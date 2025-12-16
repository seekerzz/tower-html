extends Node2D

var duration: float = 5.0
var damage_interval: float = 0.5
var timer: float = 0.0
var damage: float = 50.0
var area_size: Vector2i = Vector2i(4, 4)
var radius_sq: float = 0.0

func _ready():
	# Visuals
	var particles = CPUParticles2D.new()
	particles.amount = 50
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	# 4x4 tiles = 240x240 pixels roughly.
	particles.emission_rect_extents = Vector2(120, 120)
	particles.gravity = Vector2(0, 98)
	particles.color = Color.ORANGE_RED
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.lifetime = 0.8
	add_child(particles)

	# Calculate radius for damage check (approximation)
	# 4x4 area centered. Center to edge is about 120.
	radius_sq = 120.0 * 120.0

func init(dmg_val: float):
	damage = dmg_val

func _process(delta):
	timer += delta
	if timer >= damage_interval:
		timer -= damage_interval
		_deal_damage()

	duration -= delta
	if duration <= 0:
		queue_free()

func _deal_damage():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if global_position.distance_squared_to(enemy.global_position) <= radius_sq:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage, null, "fire")

				# Optional: Visual hit effect
				GameManager.spawn_floating_text(enemy.global_position, str(int(damage)), Color.ORANGE)

extends Node2D

var duration: float = 5.0
var tick_timer: float = 0.0
var damage_per_tick: float = 0.0

func init(dmg: float, radius: int = 1):
	damage_per_tick = dmg

	var total_size = (radius * 2 + 1) * Constants.TILE_SIZE

	# Visual setup
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(total_size, total_size)
	color_rect.position = -color_rect.size / 2
	color_rect.color = Color(1.0, 0.3, 0.0, 0.3) # Orange translucent
	add_child(color_rect)

	# Particles (Simple simulated rain)
	var particles = CPUParticles2D.new()
	particles.amount = 50
	particles.lifetime = 0.8
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(total_size / 2.0, total_size / 2.0)
	particles.gravity = Vector2(0, 200)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(1.0, 0.5, 0.0)
	add_child(particles)
	particles.emitting = true

	# Detection Area
	var area = Area2D.new()
	var shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(total_size, total_size)
	shape.shape = rect_shape
	area.add_child(shape)
	add_child(area)

	# Store area for processing
	self.set_meta("damage_area", area)

func _process(delta):
	duration -= delta
	if duration <= 0:
		queue_free()
		return

	tick_timer -= delta
	if tick_timer <= 0:
		tick_timer = 0.5
		_deal_damage()

func _deal_damage():
	var area = get_meta("damage_area")
	if !area: return

	# Use overlapping bodies/areas
	# Assuming enemies are Area2D or RigidBody2D on collision layer that Area2D detects.
	# Usually need to set collision mask/layer.
	# Let's assume default checks all, or we manually check 'enemies' group.

	var bodies = area.get_overlapping_areas()
	bodies.append_array(area.get_overlapping_bodies())

	for body in bodies:
		# Check if parent is enemy
		var enemy = body.get_parent()
		if enemy.is_in_group("enemies"):
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage_per_tick, self, "fire", self, 0.0)
		elif body.is_in_group("enemies"): # If body itself is enemy
			if body.has_method("take_damage"):
				body.take_damage(damage_per_tick, self, "fire", self, 0.0)

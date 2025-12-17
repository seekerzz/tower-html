extends Node2D

var duration: float = 5.0
var damage_interval: float = 0.5
var damage_timer: float = 0.0
var damage_amount: float = 0.0
var area_size: Vector2i = Vector2i(3, 3)

var unit_owner: Node2D = null

func setup(pos: Vector2, size: Vector2i, damage: float, owner_unit: Node2D):
	position = pos
	area_size = size
	damage_amount = damage
	unit_owner = owner_unit

	# Update visual size
	var visual = $ColorRect
	if visual:
		visual.size = Vector2(size.x * 60, size.y * 60)
		visual.position = -visual.size / 2

	var area_shape = $Area2D/CollisionShape2D
	if area_shape:
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(size.x * 60, size.y * 60)
		area_shape.shape = rect_shape

func _process(delta):
	duration -= delta
	if duration <= 0:
		queue_free()
		return

	damage_timer -= delta
	if damage_timer <= 0:
		damage_timer = damage_interval
		_deal_damage()

func _deal_damage():
	if not has_node("Area2D"): return
	var enemies = $Area2D.get_overlapping_bodies()
	for body in enemies:
		if body.is_in_group("enemies"):
			# Assuming enemies have a take_damage method
			if body.has_method("take_damage"):
				body.take_damage(damage_amount, unit_owner, "fire")

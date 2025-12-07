extends Node2D

var target = null # Enemy node
var speed: float = 400.0
var damage: float = 10.0
var life: float = 2.0
var type: String = "dot" # dot, rocket, etc.
var hit_list = []

func setup(start_pos, target_node, dmg, proj_speed, proj_type):
	position = start_pos
	target = target_node
	damage = dmg
	speed = proj_speed
	type = proj_type

	if target:
		look_at(target.global_position)

func _process(delta):
	life -= delta
	if life <= 0:
		queue_free()
		return

	var direction = Vector2.RIGHT.rotated(rotation)
	if is_instance_valid(target):
		var target_dir = (target.global_position - global_position).normalized()
		# Simple homing or just move towards last known pos?
		# For now, let's just move straight if it's not homing, or update rotation if homing
		# The reference uses simple movement towards target position (at launch time) for most,
		# but let's make it standard projectile movement.
		direction = target_dir
		look_at(target.global_position)

	position += direction * speed * delta

func _on_area_2d_area_entered(area):
	if area.is_in_group("enemies"):
		if area in hit_list: return
		hit_list.append(area)

		area.take_damage(damage)
		queue_free()

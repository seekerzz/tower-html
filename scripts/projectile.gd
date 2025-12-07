extends Node2D

var target: Node2D
var speed: float = 400.0
var damage: float = 10.0
var life: float = 2.0

func _process(delta):
	if !is_instance_valid(target):
		queue_free()
		return

	var direction = (target.position - position).normalized()
	position += direction * speed * delta

	if position.distance_to(target.position) < 10:
		target.take_damage(damage)
		queue_free()

	life -= delta
	if life <= 0:
		queue_free()

func _draw():
	draw_circle(Vector2.ZERO, 5, Color.YELLOW)

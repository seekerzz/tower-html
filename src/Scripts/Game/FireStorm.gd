extends Node2D

var damage: float = 50.0 # Default, should be set by spawner
var duration: float = 5.0
var tick_rate: float = 0.5
var tick_timer: float = 0.0
var area: Area2D

func _ready():
	# Auto-destruct after duration
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(queue_free)

	area = $Area2D

	# Visual effect (placeholder)
	var color_rect = ColorRect.new()
	color_rect.color = Color(1, 0, 0, 0.3)
	color_rect.size = Vector2(180, 180) # 3x3 grid approx
	color_rect.position = Vector2(-90, -90) # Center it
	add_child(color_rect)

func _process(delta):
	tick_timer += delta
	if tick_timer >= tick_rate:
		tick_timer = 0.0
		_deal_damage()

func _deal_damage():
	if !area: return
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			if body.has_method("take_damage"):
				body.take_damage(damage, null, "fire")
				# Optional: Visual hit feedback

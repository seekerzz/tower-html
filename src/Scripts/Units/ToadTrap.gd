extends Area2D
class_name ToadTrap

@export var duration: float = 25.0
@export var trigger_radius: float = 30.0

var owner_toad: Node2D
var level: int
var triggered: bool = false

signal trap_triggered(enemy, trap)

func _ready():
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

	body_entered.connect(_on_body_entered)
	queue_redraw()

func _draw():
	draw_circle(Vector2.ZERO, trigger_radius, Color(0.5, 0.0, 0.5, 0.5))
	draw_arc(Vector2.ZERO, trigger_radius, 0, TAU, 32, Color.PURPLE, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-10, 5), "☠️", HORIZONTAL_ALIGNMENT_CENTER, -1, 20)

func _on_body_entered(body: Node):
	if triggered or not body.is_in_group("enemies"):
		return
	triggered = true
	trap_triggered.emit(body, self)
	_play_trigger_effect()
	queue_free()

func _play_trigger_effect():
	GameManager.spawn_floating_text(global_position, "Trap!", Color.PURPLE)

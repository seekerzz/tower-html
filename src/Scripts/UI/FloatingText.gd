extends Node2D

@onready var label = $Label
@onready var anim = $AnimationPlayer

func setup(value: String, color: Color):
	label.text = value
	label.modulate = color
	# Simple randomized offset to avoid overlap
	position += Vector2(randf_range(-10, 10), randf_range(-10, 10))
	anim.play("float_up")

func _on_animation_finished(anim_name):
	queue_free()

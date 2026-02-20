extends StatusEffect
class_name PetrifiedStatus

var original_color: Color
var petrify_color: Color = Color(0.6, 0.6, 0.6, 1.0)
var petrify_source: Node = null

func _init(duration: float = 1.0):
	type_key = "petrified"
	self.duration = duration

func setup(target: Node, source: Object, params: Dictionary):
	super.setup(target, source, params)

	petrify_source = source
	if params.has("duration"):
		self.duration = params.duration

	if target is Node2D: # Assuming Enemy extends Node2D/CharacterBody2D
		original_color = target.modulate
		target.modulate = petrify_color

		# Stop movement by applying stun
		if target.has_method("apply_stun"):
			target.apply_stun(duration)

func _exit_tree():
	var target = get_parent()
	if is_instance_valid(target) and (target is Node2D):
		target.modulate = original_color

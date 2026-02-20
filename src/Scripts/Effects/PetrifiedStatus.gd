extends StatusEffect
class_name PetrifiedStatus

var original_color: Color
var petrify_color: Color = Color.GRAY
var petrify_source: Node = null

func _init(duration: float = 1.0):
	type_key = "petrified"
	self.duration = duration

func setup(target: Node, source: Object, params: Dictionary):
	super.setup(target, source, params)

	petrify_source = source
	if params.has("duration"):
		self.duration = params.duration

	if target is Node2D:
		original_color = target.modulate
		target.modulate = petrify_color
		target.set_meta("is_petrified", true)

		# Modify collision layer: Remove from Enemy (2), Add to Petrified (10)
		if target is CollisionObject2D:
			target.set_collision_layer_value(2, false)
			target.set_collision_layer_value(10, true)

		# Stop movement by applying stun
		if target.has_method("apply_stun"):
			target.apply_stun(duration)

func _exit_tree():
	var target = get_parent()
	if is_instance_valid(target) and (target is Node2D):
		target.modulate = original_color
		target.remove_meta("is_petrified")

		# Restore collision layer
		if target is CollisionObject2D:
			target.set_collision_layer_value(2, true)
			target.set_collision_layer_value(10, false)

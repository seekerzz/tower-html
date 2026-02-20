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
		target.set_meta("petrify_source", source)  # 保存引用用于伤害计算

		# 冻结动画
		if target.get("visual_controller"):
			target.visual_controller.set_idle_enabled(false)

		# Stop movement by applying stun
		if target.has_method("apply_stun"):
			target.apply_stun(duration)

func apply(delta: float):
	duration -= delta
	if duration <= 0:
		_on_expire()
		queue_free()

func _on_expire():
	var target = get_parent()
	if not (target and is_instance_valid(target)):
		return

	if petrify_source and is_instance_valid(petrify_source):
		var level = 1
		if "level" in petrify_source:
			level = petrify_source.level

		# Lv3: End damage (Deal target MaxHP damage)
		if level >= 3:
			if target.has_method("take_damage"):
				# Use magic damage type
				var damage_amount = 0
				if "max_hp" in target:
					damage_amount = target.max_hp

				if damage_amount > 0:
					target.take_damage(damage_amount, petrify_source, "magic")

func _exit_tree():
	var target = get_parent()
	if is_instance_valid(target) and (target is Node2D):
		target.modulate = original_color
		target.remove_meta("is_petrified")
		target.remove_meta("petrify_source")

		# 恢复动画
		if target.get("visual_controller"):
			target.visual_controller.set_idle_enabled(true)

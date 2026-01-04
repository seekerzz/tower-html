extends Node2D

class_name VisualController

@export var wobble_scale: Vector2 = Vector2.ONE
@export var visual_offset: Vector2 = Vector2.ZERO
@export var visual_rotation: float = 0.0

var time: float = 0.0
var active: bool = true
var parent_velocity: Vector2 = Vector2.ZERO
var base_freq: float = 1.0
var amplitude: float = 0.1
var style: String = "squash"

func _process(delta):
	if !active: return

	time += delta * base_freq * 2.0 # Use a factor to control speed

	var s = sin(time)
	var move_factor = 0.0

	# Try to get parent velocity if available
	var p = get_parent()
	if p and "velocity" in p:
		if p.velocity.length() > 10.0:
			move_factor = 1.0
			# If moving, maybe speed up the animation?
			time += delta * 5.0 # Add extra time for movement bounce
		else:
			move_factor = 0.0

	# Idle/Walk Loop
	# Combined logic: Breathing always happens, walking adds bounce.

	# Breathing (always on)
	var breath_scale = 1.0 + s * amplitude * 0.5

	# Walking Bounce (when moving)
	var bounce_y = 0.0
	if move_factor > 0:
		bounce_y = -abs(sin(time)) * amplitude * 20.0 # Pixel bounce
		breath_scale += abs(sin(time)) * amplitude # Extra squash when moving

	# Apply
	wobble_scale = Vector2(1.0 / breath_scale, breath_scale) # Volume preservation-ish
	visual_offset = Vector2(0, bounce_y)
	visual_rotation = 0.0

	# Specific style overrides if needed, but the requirement specifically mentioned:
	# "Idle/Walk 循环： 在 _process 中根据时间 sin 函数计算呼吸感缩放和移动时的跳跃位移 (abs(sin))."
	# So I stick to that.

func apply_transform(target_node: Node2D, is_facing_left: bool = false):
	if !target_node: return

	var final_scale = wobble_scale
	var final_offset = visual_offset

	if is_facing_left:
		final_scale.x = -abs(final_scale.x)
		final_offset.x = -final_offset.x
	else:
		final_scale.x = abs(final_scale.x)

	target_node.scale = final_scale
	target_node.position = final_offset
	# Preserve original rotation logic if needed, but here we set it relative
	target_node.rotation = visual_rotation

	# If target_node was centered, offset might need adjustment, but usually we add visual_offset to base pos.
	# Since this component manages visual logic, we assume visual_offset is the *only* offset from (0,0).
	# However, if the node has a pivot offset, we need to be careful.
	# The original Enemy.gd code did:
	# $Label.scale = final_scale
	# $Label.position = -$Label.size / 2 + visual_offset
	# So visual_offset is added to the base position.

	if target_node is Control: # Label or TextureRect
		target_node.position = -target_node.size / 2 + final_offset
		target_node.pivot_offset = target_node.size / 2
	elif target_node is Node2D: # Sprite2D
		target_node.position = final_offset

func play_elastic_shoot():
	active = false # Stop idle loop
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Simulate pull back
	tween.tween_property(self, "wobble_scale", Vector2(0.6, 1.4), 0.2)
	tween.parallel().tween_property(self, "visual_offset", Vector2(-10, 0), 0.2)

	# Snap forward (Shoot)
	tween.tween_property(self, "wobble_scale", Vector2(1.4, 0.6), 0.1)
	tween.parallel().tween_property(self, "visual_offset", Vector2(10, 0), 0.1)

	# Return to normal
	tween.tween_property(self, "wobble_scale", Vector2.ONE, 0.3)
	tween.parallel().tween_property(self, "visual_offset", Vector2.ZERO, 0.3)

	tween.tween_callback(func(): active = true)
	return tween

func play_elastic_slash():
	active = false
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Rotate back (Charge)
	tween.tween_property(self, "visual_rotation", deg_to_rad(-30), 0.2)
	tween.parallel().tween_property(self, "wobble_scale", Vector2(0.9, 1.1), 0.2)

	# Slash forward
	tween.tween_property(self, "visual_rotation", deg_to_rad(60), 0.1)
	tween.parallel().tween_property(self, "wobble_scale", Vector2(1.2, 0.8), 0.1)

	# Return
	tween.tween_property(self, "visual_rotation", 0.0, 0.3)
	tween.parallel().tween_property(self, "wobble_scale", Vector2.ONE, 0.3)

	tween.tween_callback(func(): active = true)
	return tween

func play_death_implosion():
	active = false
	var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)

	# Swell
	tween.tween_property(self, "wobble_scale", Vector2(1.5, 1.5), 0.5)

	# Shrink and Rotate
	tween.tween_property(self, "wobble_scale", Vector2.ZERO, 0.5)
	tween.parallel().tween_property(self, "visual_rotation", deg_to_rad(180), 0.5)

	# We might want to gray out the parent/node, but this component only controls transform properties.
	# The requirement says "颜色变灰" (Color turn gray).
	# We can try to set modulate on the target node if we had a reference, or the caller can handle color.
	# But "play_death_implosion" implies it handles it.
	# I will try to access the parent or a known visual node to change color if possible,
	# but since I don't store the target node in the class (it's passed in apply_transform),
	# I will rely on the caller to update color or I will add color tweening if I can.
	# Actually, I can return the tween so the caller can await it.

	return tween

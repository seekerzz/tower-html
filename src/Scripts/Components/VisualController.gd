extends Node2D

class_name VisualController

# Properties to be accessed by the parent
var wobble_scale: Vector2 = Vector2.ONE
var visual_offset: Vector2 = Vector2.ZERO
var visual_rotation: float = 0.0

var _anim_time: float = 0.0
var _anim_tween: Tween

# Helper to control amplitude/frequency if needed, can be set from parent
var idle_amplitude: float = 0.05
var idle_freq: float = 4.0
var anim_style: String = "bouncy_idle"

# To detect movement for walking bounce
var _parent_velocity: Vector2 = Vector2.ZERO
var _parent_speed: float = 0.0 # Used for frequency scaling

func _process(delta: float):
	# If an animation tween is running (attack/death), we might want to skip idle proc
	# depending on design. Usually attack overrides idle.
	if _anim_tween and _anim_tween.is_valid() and _anim_tween.is_running():
		return

	_anim_time += delta * idle_freq * 2.0 # Factor to match previous speed feels

	# Determine if moving (based on parent velocity if available)
	# We will assume the parent updates us or we can access parent.velocity if it's a CharacterBody2D
	var parent = get_parent()
	var is_moving = false
	if parent and "velocity" in parent:
		is_moving = parent.velocity.length() > 10.0

	if is_moving:
		# Walking bounce: abs(sin)
		var s = abs(sin(_anim_time))
		visual_offset = Vector2(0, -s * idle_amplitude * 100.0) # Scale amp to pixels roughly
		wobble_scale = Vector2(1.0 + s * idle_amplitude, 1.0 - s * idle_amplitude)
		visual_rotation = sin(_anim_time * 0.5) * idle_amplitude * 2.0
	else:
		# Idle breathing
		var s = sin(_anim_time)
		wobble_scale = Vector2(1.0 + s * idle_amplitude, 1.0 - s * idle_amplitude)
		visual_offset = Vector2.ZERO
		visual_rotation = 0.0

	# Apply transform immediately if we want this component to handle it
	# But the instructions say "Provide apply_transform helper" or similar.
	# The parent script is instructed to call apply_transform.

func apply_transform(target_node: Node2D):
	if !target_node: return

	target_node.scale = wobble_scale
	target_node.position = visual_offset
	# Reset position centering if needed. Assuming visual_offset is delta from center.
	# The previous code did: position = -size/2 + visual_offset.
	# So we should probably let the parent handle the base position or pass it in.
	# But wait, wobble_scale is multiplicative.
	# The parent code was:
	# $TextureRect.scale = final_scale
	# $TextureRect.position = -$TextureRect.size / 2 + visual_offset
	# $TextureRect.rotation = visual_rotation

	# So `visual_offset` is the animation offset.
	# We can just set the properties we manage.
	# However, if target_node is a Control (TextureRect), position is top-left.
	# If it's a Sprite2D, position is center (usually).

	target_node.rotation = visual_rotation
	target_node.scale = wobble_scale

	# Position handling is tricky because it depends on the anchor/pivot.
	# The VisualController calculates the *offset*.
	# If the caller uses this, they should add this offset to their base position.
	# But the prompt says "apply_transform(target_node) ... apply calculated scale/offset/rotation".
	# I'll implement it such that it sets the values, assuming the parent has set up pivots correctly.
	# For TextureRect in Enemy.gd: `tex_rect.pivot_offset = tex_rect.size / 2`.
	# So setting rotation/scale works fine around center.
	# Position: `tex_rect.position = -tex_rect.size / 2` (centered).
	# So we need to add visual_offset to that.

	if target_node is Control:
		target_node.position = -target_node.size / 2 + visual_offset
	elif target_node is Node2D:
		# For Sprite2D centered at 0,0
		target_node.position = visual_offset


func play_elastic_shoot():
	if _anim_tween: _anim_tween.kill()
	_anim_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Simulate Pulling Bow (Anticipation)
	# Scale thin (x < 1, y > 1), Offset back
	_anim_tween.tween_property(self, "wobble_scale", Vector2(0.6, 1.4), 0.2)
	_anim_tween.parallel().tween_property(self, "visual_offset", Vector2(-10, 0), 0.2)

	# Fire (Release) -> Rebound
	_anim_tween.tween_property(self, "wobble_scale", Vector2(1.3, 0.7), 0.1)
	_anim_tween.parallel().tween_property(self, "visual_offset", Vector2(10, 0), 0.1)

	# Return to normal
	_anim_tween.tween_property(self, "wobble_scale", Vector2.ONE, 0.4)
	_anim_tween.parallel().tween_property(self, "visual_offset", Vector2.ZERO, 0.4)

	await _anim_tween.finished

func play_elastic_slash():
	if _anim_tween: _anim_tween.kill()
	_anim_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Windup (Rotate back)
	_anim_tween.tween_property(self, "visual_rotation", deg_to_rad(-45), 0.2)
	_anim_tween.parallel().tween_property(self, "wobble_scale", Vector2(0.8, 1.2), 0.2)

	# Slash (Rotate forward fast)
	_anim_tween.tween_property(self, "visual_rotation", deg_to_rad(90), 0.1)
	_anim_tween.parallel().tween_property(self, "wobble_scale", Vector2(1.4, 0.6), 0.1)

	# Return
	_anim_tween.tween_property(self, "visual_rotation", 0.0, 0.4)
	_anim_tween.parallel().tween_property(self, "wobble_scale", Vector2.ONE, 0.4)

	await _anim_tween.finished

func play_death_implosion(target_node: Node2D = null):
	if _anim_tween: _anim_tween.kill()
	_anim_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# Swell
	_anim_tween.tween_property(self, "wobble_scale", Vector2(1.2, 1.2), 0.2)

	# Implode (Shrink to 0, Rotate 180)
	_anim_tween.tween_property(self, "wobble_scale", Vector2.ZERO, 0.5)
	_anim_tween.parallel().tween_property(self, "visual_rotation", deg_to_rad(180), 0.5)

	# Color change
	if target_node:
		_anim_tween.parallel().tween_property(target_node, "modulate", Color.GRAY, 0.5)

	await _anim_tween.finished

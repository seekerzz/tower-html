extends Control

var active_tween: Tween

@onready var visual_root = $Template/VisualRoot
@onready var skeleton = $Template/VisualRoot/Skeleton2D
# Access bones via path relative to Skeleton2D or VisualRoot
# Structure: VisualRoot/Skeleton2D/Torso/LegL
# We need to be careful if paths change, but based on template.tscn:
@onready var leg_l = $Template/VisualRoot/Skeleton2D/Torso/LegL
@onready var leg_r = $Template/VisualRoot/Skeleton2D/Torso/LegR
@onready var arm_r = $Template/VisualRoot/Skeleton2D/Torso/ArmR

func _ready():
	# Connect buttons
	$UI/HBoxContainer/IdleBtn.pressed.connect(play_idle)
	$UI/HBoxContainer/WalkBtn.pressed.connect(play_walk)
	$UI/HBoxContainer/AttackBtn.pressed.connect(play_attack)
	$UI/HBoxContainer/DeathBtn.pressed.connect(play_death)

	# Start idle by default
	play_idle()

func reset_pose():
	if active_tween:
		active_tween.kill()

	# Reset VisualRoot
	if visual_root:
		visual_root.scale = Vector2.ONE
		visual_root.rotation = 0
		visual_root.position = Vector2.ZERO
		visual_root.modulate.a = 1.0

	# Reset Bones
	if leg_l: leg_l.rotation = 0
	if leg_r: leg_r.rotation = 0
	if arm_r: arm_r.rotation = 0

func play_idle():
	reset_pose()
	if not visual_root: return

	active_tween = create_tween().set_loops()

	# Breathing: Scale Y 0.95 <-> 1.05
	# Period 1.5s (0.75s each way)

	# 1. Inhale (or Exhale)
	active_tween.tween_property(visual_root, "scale", Vector2(1.0/1.05, 1.05), 0.75)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 2. Exhale (or Inhale)
	active_tween.tween_property(visual_root, "scale", Vector2(1.0/0.95, 0.95), 0.75)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func play_walk():
	reset_pose()
	if not visual_root: return

	active_tween = create_tween().set_loops()

	# Walk Cycle Duration
	var step_duration = 0.3
	var half_step = step_duration / 2.0

	# We will do sequential steps, each containing parallel tweens

	# --- Step 1: Jump UP ---
	# Pos Y -> -10
	# Scale -> (0.9, 1.1) (Stretch)
	# Legs: Scissor. LegL forward, LegR backward

	active_tween.set_parallel(true)
	active_tween.tween_property(visual_root, "position:y", -10.0, half_step)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(visual_root, "scale", Vector2(0.9, 1.1), half_step)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if leg_l:
		active_tween.tween_property(leg_l, "rotation_degrees", 30.0, half_step)
	if leg_r:
		active_tween.tween_property(leg_r, "rotation_degrees", -30.0, half_step)

	active_tween.set_parallel(false) # End of Up phase

	# --- Step 2: Fall DOWN ---
	# Pos Y -> 0
	# Scale -> (1.1, 0.9) (Squash on impact)
	# Legs: Swap? Or return to neutral?
	# Usually walk cycle involves two steps (Left then Right).
	# But prompt says "每 0.3秒做一次 position.y 的跳跃".
	# If we want a full walk cycle (L-R), we might need two jumps in the loop.
	# "双腿 ... 简单的剪刀差旋转（±30度）"
	# Let's do a simple bounce where legs swap each jump? Or just oscillate?
	# Let's try to make it look like a continuous walk.

	# Actually, usually one jump = one step.
	# So we need to alternate legs.
	# But `set_loops()` loops the defined sequence.
	# If I define ONE jump, the legs will reset or jump same way every time.
	# To alternate legs, I should define TWO jumps in the sequence.

	# Wait, I just wrote the "Up" phase. Now "Down" phase.
	active_tween.set_parallel(true)
	active_tween.tween_property(visual_root, "position:y", 0.0, half_step)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	active_tween.tween_property(visual_root, "scale", Vector2(1.1, 0.9), half_step)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Legs return to near 0 or swap?
	# If I want them to swap for the next step, I should probably tween them to the OTHER side in the next jump.
	# But let's keep it simple as requested: "LegL/LegR ... 简单的剪刀差旋转".
	# If I put them back to 0 at bottom, it looks like a hop.
	if leg_l:
		active_tween.tween_property(leg_l, "rotation_degrees", 0.0, half_step)
	if leg_r:
		active_tween.tween_property(leg_r, "rotation_degrees", 0.0, half_step)

	active_tween.set_parallel(false)

	# To make it alternate, I should repeat the Up/Down but with swapped legs.

	# --- Step 3: Jump UP (Alternate Legs) ---
	active_tween.set_parallel(true)
	active_tween.tween_property(visual_root, "position:y", -10.0, half_step)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(visual_root, "scale", Vector2(0.9, 1.1), half_step)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if leg_l:
		active_tween.tween_property(leg_l, "rotation_degrees", -30.0, half_step)
	if leg_r:
		active_tween.tween_property(leg_r, "rotation_degrees", 30.0, half_step)
	active_tween.set_parallel(false)

	# --- Step 4: Fall DOWN (Alternate Legs) ---
	active_tween.set_parallel(true)
	active_tween.tween_property(visual_root, "position:y", 0.0, half_step)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	active_tween.tween_property(visual_root, "scale", Vector2(1.1, 0.9), half_step)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	if leg_l:
		active_tween.tween_property(leg_l, "rotation_degrees", 0.0, half_step)
	if leg_r:
		active_tween.tween_property(leg_r, "rotation_degrees", 0.0, half_step)
	active_tween.set_parallel(false)


func play_attack():
	reset_pose()
	if not visual_root: return

	active_tween = create_tween()

	# Phase 1: Windup (0.2s)
	# Backward, Rotate -15, Squash (1.1, 0.9)
	active_tween.set_parallel(true)
	active_tween.tween_property(visual_root, "rotation_degrees", -15.0, 0.2)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(visual_root, "position:x", -20.0, 0.2)
	active_tween.tween_property(visual_root, "scale", Vector2(1.1, 0.9), 0.2)
	active_tween.set_parallel(false)

	# Phase 2: Strike (0.1s)
	# Forward, Rotate +10, Stretch (1.2, 0.8), ArmR rotate
	active_tween.set_parallel(true)
	active_tween.tween_property(visual_root, "position:x", 50.0, 0.1)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(visual_root, "scale", Vector2(1.2, 0.8), 0.1)
	active_tween.tween_property(visual_root, "rotation_degrees", 10.0, 0.1)
	if arm_r:
		# Assuming initial is 0, rotate down. Since ArmR points right usually?
		# Template ArmR rotation is 1.16 rad (~66 deg).
		# Reset sets it to 0 (relative to parent).
		# If we want "down", maybe +90 degrees?
		active_tween.tween_property(arm_r, "rotation_degrees", 90.0, 0.1)
	active_tween.set_parallel(false)

	# Phase 3: Recovery (0.4s)
	# Elastic return
	active_tween.set_parallel(true)
	active_tween.tween_property(visual_root, "position", Vector2.ZERO, 0.4)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(visual_root, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(visual_root, "rotation", 0.0, 0.4)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if arm_r:
		active_tween.tween_property(arm_r, "rotation", 0.0, 0.4)\
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	active_tween.set_parallel(false)

func play_death():
	reset_pose()
	if not visual_root: return

	active_tween = create_tween()
	active_tween.set_parallel(true)

	# Rotate 90
	active_tween.tween_property(visual_root, "rotation_degrees", 90.0, 0.5)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# Scale -> 0
	active_tween.tween_property(visual_root, "scale", Vector2.ZERO, 0.5)

	# Alpha -> 0
	active_tween.tween_property(visual_root, "modulate:a", 0.0, 0.5)

extends Control

@onready var character = $Template
@onready var visual_root = character.get_node("VisualRoot")
@onready var leg_l = visual_root.get_node("Skeleton2D/Torso/LegL")
@onready var leg_r = visual_root.get_node("Skeleton2D/Torso/LegR")
@onready var arm_r = visual_root.get_node("Skeleton2D/Torso/ArmR")

@onready var btn_idle = $UI/Buttons/Idle
@onready var btn_walk = $UI/Buttons/Walk
@onready var btn_attack = $UI/Buttons/Attack
@onready var btn_death = $UI/Buttons/Death

var active_tween: Tween

func _ready():
	btn_idle.pressed.connect(play_idle)
	btn_walk.pressed.connect(play_walk)
	btn_attack.pressed.connect(play_attack)
	btn_death.pressed.connect(play_death)

	# Start with Idle
	play_idle()

func reset_visuals():
	if active_tween:
		active_tween.kill()

	visual_root.position = Vector2.ZERO
	visual_root.rotation = 0
	visual_root.scale = Vector2.ONE
	visual_root.modulate.a = 1.0

	leg_l.rotation = 0
	leg_r.rotation = 0
	arm_r.rotation = 0

func play_idle():
	reset_visuals()
	active_tween = create_tween().set_loops()

	# Scale.y 0.95 -> 1.05
	# Scale.x = 1.0 / Scale.y
	# Period 1.5s

	var duration = 0.75 # Half of 1.5s

	# Breathing cycle
	active_tween.tween_property(visual_root, "scale", Vector2(1.0/1.05, 1.05), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(visual_root, "scale", Vector2(1.0/0.95, 0.95), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func play_walk():
	reset_visuals()
	active_tween = create_tween().set_loops()

	# Walk Cycle (Bouncy)
	# Cycle time for body bounce: 0.3s
	# Cycle time for legs: 0.6s (2 bounces)

	var step_time = 0.3

	# Set initial state for loop start
	visual_root.scale = Vector2(1.1, 0.9)
	leg_l.rotation_degrees = -30
	leg_r.rotation_degrees = 30

	# --- Step 1 (Left Leg Forward -> Backward) ---
	# Up phase (0.15s)
	active_tween.tween_property(visual_root, "position:y", -10, step_time/2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(visual_root, "scale", Vector2(0.9, 1.1), step_time/2)
	active_tween.parallel().tween_property(leg_l, "rotation_degrees", 0, step_time/2)
	active_tween.parallel().tween_property(leg_r, "rotation_degrees", 0, step_time/2)

	# Down phase (0.15s)
	active_tween.chain().tween_property(visual_root, "position:y", 0, step_time/2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	active_tween.parallel().tween_property(visual_root, "scale", Vector2(1.1, 0.9), step_time/2)
	active_tween.parallel().tween_property(leg_l, "rotation_degrees", 30, step_time/2)
	active_tween.parallel().tween_property(leg_r, "rotation_degrees", -30, step_time/2)

	# --- Step 2 (Right Leg Forward -> Backward) ---
	# Up phase (0.15s)
	active_tween.chain().tween_property(visual_root, "position:y", -10, step_time/2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(visual_root, "scale", Vector2(0.9, 1.1), step_time/2)
	active_tween.parallel().tween_property(leg_l, "rotation_degrees", 0, step_time/2)
	active_tween.parallel().tween_property(leg_r, "rotation_degrees", 0, step_time/2)

	# Down phase (0.15s)
	active_tween.chain().tween_property(visual_root, "position:y", 0, step_time/2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	active_tween.parallel().tween_property(visual_root, "scale", Vector2(1.1, 0.9), step_time/2)
	active_tween.parallel().tween_property(leg_l, "rotation_degrees", -30, step_time/2)
	active_tween.parallel().tween_property(leg_r, "rotation_degrees", 30, step_time/2)

func play_attack():
	reset_visuals()
	active_tween = create_tween()

	# Phase 1: Windup (0.2s) - Lean back, compress
	active_tween.tween_property(visual_root, "rotation_degrees", -15, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(visual_root, "position:x", -20, 0.2)
	active_tween.parallel().tween_property(visual_root, "scale", Vector2(1.1, 0.9), 0.2)

	# Phase 2: Strike (0.1s) - Lunge forward, stretch, arm swing
	active_tween.chain().tween_property(visual_root, "rotation_degrees", 10, 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(visual_root, "position:x", 50, 0.1)
	active_tween.parallel().tween_property(visual_root, "scale", Vector2(1.2, 0.8), 0.1)
	# Rotate ArmR down. It starts at 0 (Bone2D). Let's rotate it to 100 degrees.
	active_tween.parallel().tween_property(arm_r, "rotation_degrees", 100, 0.1)

	# Phase 3: Recover (0.4s) - Bounce back
	active_tween.chain().tween_property(visual_root, "rotation_degrees", 0, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(visual_root, "position", Vector2.ZERO, 0.4)
	active_tween.parallel().tween_property(visual_root, "scale", Vector2.ONE, 0.4)
	active_tween.parallel().tween_property(arm_r, "rotation", 0, 0.4)

func play_death():
	reset_visuals()
	active_tween = create_tween()

	var duration = 0.5

	# Rotate 90 deg, Scale to 0, Fade out
	active_tween.tween_property(visual_root, "rotation_degrees", 90, duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(visual_root, "scale", Vector2.ZERO, duration)
	active_tween.parallel().tween_property(visual_root, "modulate:a", 0.0, duration)

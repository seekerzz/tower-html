extends Control

signal finished

@onready var background = $Background
@onready var portrait = $Portrait
@onready var label_subtitle = $LabelSubtitle
@onready var label_skill = $LabelSkillName
@onready var flash = $Flash

# Preload AssetLoader to avoid class_name resolution issues in some contexts
const AssetLoaderScript = preload("res://src/Scripts/Utils/AssetLoader.gd")

func setup(unit):
	var unit_color = Color.DARK_SLATE_BLUE
	var skill_name = "SKILL"
	var icon_tex = null

	# Handle both Unit object and Dictionary (for testing)
	if typeof(unit) == TYPE_DICTIONARY:
		if unit.has("color"): unit_color = unit.color
		if unit.has("skill"): skill_name = unit.skill
		# Mock icon?
		if unit.has("type_key"):
			icon_tex = AssetLoaderScript.get_unit_icon(unit.type_key)

	elif unit is Object:
		# If unit_data is present (standard Unit class)
		if "unit_data" in unit:
			if unit.unit_data.has("color"): unit_color = unit.unit_data.color
			if unit.unit_data.has("skill"): skill_name = unit.unit_data.skill

			if "type_key" in unit:
				icon_tex = AssetLoaderScript.get_unit_icon(unit.type_key)
			elif "type_key" in unit.unit_data:
				icon_tex = AssetLoaderScript.get_unit_icon(unit.unit_data.type_key)

			# Fallback if unit directly has color
			if "color" in unit: unit_color = unit.color

	# Apply setup
	if background:
		background.color = unit_color

	if label_skill:
		label_skill.text = str(skill_name).to_upper()

	if portrait and icon_tex:
		portrait.texture = icon_tex

	# Start animation
	animate_entry()

func animate_entry():
	# Initial state
	position.x = -400
	modulate.a = 1.0
	if flash: flash.color.a = 0.0

	var tween = create_tween()
	tween.set_parallel(true)
	# Slide in with overshoot
	tween.tween_property(self, "position:x", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Flash effect
	if flash:
		flash.color.a = 0.8
		tween.tween_property(flash, "color:a", 0.0, 0.5)

	# Auto exit
	get_tree().create_timer(2.5).timeout.connect(animate_exit)

func animate_exit():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:x", -300.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.finished.connect(queue_free)

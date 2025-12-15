extends Control

@onready var background_node = $Background
@onready var portrait_rect = $Portrait
@onready var label_subtitle = $LabelSubtitle
@onready var label_skill = $LabelSkill
@onready var flash_rect = $Flash

var bg_color = Color(0.2, 0.2, 0.2, 0.9)

func _ready():
	# Initial state: hidden or prepared for animation
	modulate.a = 0.0
	flash_rect.modulate.a = 0.0

	# Initial positions for animation
	portrait_rect.position.x += 50

	animate_entry()

func setup(data):
	if label_skill:
		if "skill" in data:
			label_skill.text = str(data["skill"]).to_upper()
		if "unit_data" in data and "skill" in data["unit_data"]:
			label_skill.text = str(data["unit_data"]["skill"]).to_upper()

	if "color" in data:
		bg_color = data["color"]
		if background_node:
			background_node.color = bg_color
			background_node.queue_redraw()

	if "type_key" in data and portrait_rect:
		var icon = AssetLoader.get_unit_icon(data["type_key"])
		if icon:
			portrait_rect.texture = icon

func animate_entry():
	var tween = create_tween().set_parallel(true)

	# 1. Background slide in (and whole container fade in)
	position.x = -100
	tween.tween_property(self, "position:x", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

	# 2. Portrait slide in (delayed)
	tween.tween_property(portrait_rect, "position:x", portrait_rect.position.x - 50, 0.4).set_delay(0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 3. Text impact
	label_skill.scale = Vector2(1.5, 1.5)
	label_skill.modulate.a = 0.0
	tween.tween_property(label_skill, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label_skill, "modulate:a", 1.0, 0.1).set_delay(0.2)

	# 4. Flash
	tween.tween_property(flash_rect, "modulate:a", 0.8, 0.05).set_delay(0.25)
	tween.tween_property(flash_rect, "modulate:a", 0.0, 0.2).set_delay(0.3)

func animate_exit():
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:x", -300.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(queue_free)

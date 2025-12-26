extends Control

signal core_selected(core_type)

func _ready():
	# Ensure background or layout is set up
	var panel = Panel.new()
	panel.layout_mode = 1
	panel.anchors_preset = 15
	add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.layout_mode = 1
	hbox.anchors_preset = 15
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 50)
	panel.add_child(hbox)

	var core_types = ["abundance", "moon_well", "holy_sword"]

	# Safety check for data manager
	var data = {}
	if GameManager.data_manager:
		data = GameManager.data_manager.get_data("CORE_TYPES")

	for type in core_types:
		var def = data.get(type, {})
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(200, 300)
		btn.text = "%s\n\n%s" % [def.get("name", type), def.get("desc", "")]
		btn.pressed.connect(func(): _on_core_selected(type))
		hbox.add_child(btn)

func _on_core_selected(type):
	print("Selected Core: ", type)
	GameManager.core_type = type
	GameManager.distribute_wave_item()
	get_tree().change_scene_to_file("res://src/Scenes/Game/MainGame.tscn")

extends Control

const CARD_SCENE = preload("res://src/Scenes/UI/CoreCard.tscn") # We will need to create this or do it inline

func _ready():
	var container = $CenterContainer/HBoxContainer
	var core_types = Constants.CORE_TYPES

	# Clear existing
	for child in container.get_children():
		child.queue_free()

	for key in core_types:
		var data = core_types[key]
		var button = Button.new()
		button.text = data["name"] + "\n" + data["desc"]
		button.custom_minimum_size = Vector2(200, 300)
		button.connect("pressed", func(): _on_core_selected(key))
		container.add_child(button)

func _on_core_selected(core_key: String):
	GameManager.core_type = core_key
	print("Selected Core: ", core_key)
	# Switch to Main Game
	get_tree().change_scene_to_file("res://src/Scenes/Game/MainGame.tscn")

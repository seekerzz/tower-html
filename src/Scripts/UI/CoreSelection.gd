extends Control

@onready var container = $CenterContainer/HBoxContainer

func _ready():
	_create_cards()

func _create_cards():
	var core_data = {}
	if GameManager.data_manager and GameManager.data_manager.data.has("CORE_TYPES"):
		core_data = GameManager.data_manager.data["CORE_TYPES"]
	else:
		print("Error: CORE_TYPES not found in DataManager!")
		# Fallback just in case, or show error
		return

	for key in core_data.keys():
		var data = core_data[key]
		var button = Button.new()

		# Format text
		var title = data.get("name", key)
		var desc = data.get("desc", "No description")
		button.text = "%s\n\n%s" % [title, desc]

		button.custom_minimum_size = Vector2(200, 300)
		button.pressed.connect(func(): _on_core_selected(key))
		container.add_child(button)

func _on_core_selected(core_key: String):
	GameManager.core_type = core_key

	# Load MainGame scene
	var main_game_scene = load("res://src/Scenes/Game/MainGame.tscn")
	if main_game_scene:
		get_tree().change_scene_to_packed(main_game_scene)
	else:
		print("Error: MainGame scene not found!")

extends Control

@onready var container = $ScrollContainer/HBoxContainer

var core_card_scene = preload("res://src/Scenes/UI/CoreCard.tscn")

func _ready():
	_create_cards()

func _create_cards():
	var core_data = {}
	if GameManager.data_manager and GameManager.data_manager.data.has("CORE_TYPES"):
		core_data = GameManager.data_manager.data["CORE_TYPES"]
	else:
		print("Error: CORE_TYPES not found in DataManager!")
		return

	for key in core_data.keys():
		var data = core_data[key]
		var card = core_card_scene.instantiate()
		container.add_child(card)
		card.setup(key, data)
		card.card_selected.connect(_on_core_selected)

func _on_core_selected(core_key: String):
	GameManager.core_type = core_key

	# Load MainGame scene
	var main_game_scene = load("res://src/Scenes/Game/MainGame.tscn")
	if main_game_scene:
		get_tree().change_scene_to_packed(main_game_scene)
	else:
		print("Error: MainGame scene not found!")

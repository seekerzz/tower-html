extends CanvasLayer

signal upgrade_selected(upgrade_data)

@onready var container = $Control/HBoxContainer

# Hardcoded upgrades for now
var available_upgrades = [
	{
		"id": "heal_core",
		"title": "Repair Core",
		"description": "Restore 10% of Core Health",
		"icon": null
	},
	{
		"id": "gold_boost",
		"title": "Treasure",
		"description": "Gain 50 Gold",
		"icon": null
	},
	{
		"id": "damage_boost",
		"title": "Power Up",
		"description": "Increase Global Damage by 10%",
		"icon": null
	}
]

func _ready():
	# Ensure container is empty or populated
	show_upgrades()

func show_upgrades():
	if not container:
		return

	# Clear existing children if any
	for child in container.get_children():
		child.queue_free()

	# Create cards
	for upgrade in available_upgrades:
		create_card(upgrade)

func create_card(data):
	var btn = Button.new()
	# Simple text formatting
	btn.text = "%s\n\n%s" % [data["title"], data["description"]]
	btn.custom_minimum_size = Vector2(200, 300)

	# Connect signal
	btn.pressed.connect(_on_card_pressed.bind(data))

	container.add_child(btn)

func _on_card_pressed(data):
	# Emit signal first so listener can handle it
	upgrade_selected.emit(data)
	# Then close
	queue_free()

extends CanvasLayer

signal upgrade_selected(upgrade_data)

@onready var container = $Control/HBoxContainer

func _ready():
	# Ensure container is empty or populated
	show_upgrades()

func show_upgrades():
	if not container:
		return

	# Clear existing children if any
	for child in container.get_children():
		child.queue_free()

	# Fetch rewards from RewardManager
	var rewards = []
	var rm = GameManager.get("reward_manager")
	if not rm and GameManager.has_meta("reward_manager"):
		rm = GameManager.get_meta("reward_manager")

	if rm:
		rewards = rm.get_random_rewards(3)
	else:
		# Fallback if RewardManager is not attached yet
		rewards = [
			{
				"id": "heal_core", # Keeps old ID for compatibility if needed, or we use new ones but add handling
				"name": "Repair Core (Fallback)",
				"desc": "RewardManager not found",
				"icon": null
			}
		]

	# Create cards
	for upgrade in rewards:
		create_card(upgrade)

func create_card(data):
	var btn = Button.new()
	# Simple text formatting
	# Adjust for data keys: title->name, description->desc
	var title = data.get("name", data.get("title", "Unknown"))
	var desc = data.get("desc", data.get("description", ""))

	btn.text = "%s\n\n%s" % [title, desc]
	btn.custom_minimum_size = Vector2(200, 300)

	if data.get("rarity") == "epic":
		btn.modulate = Color(1, 0.5, 1) # Purpleish
	elif data.get("rarity") == "rare":
		btn.modulate = Color(0.2, 0.6, 1) # Blueish

	# Connect signal
	btn.pressed.connect(_on_card_pressed.bind(data))

	container.add_child(btn)

func _on_card_pressed(data):
	# Add reward via RewardManager
	var rm = GameManager.get("reward_manager")
	if not rm and GameManager.has_meta("reward_manager"):
		rm = GameManager.get_meta("reward_manager")

	if rm:
		rm.add_reward(data["id"])
	else:
		# Fallback for old logic if needed, but GameManager._on_upgrade_selected handles specific IDs
		# If we use new IDs, GameManager needs to know them or we rely on RewardManager.
		# RewardManager.add_reward handles the logic.
		# So we assume RewardManager does the job.
		pass

	# Emit signal first so listener can handle it (e.g. unpause, close menu)
	upgrade_selected.emit(data)
	# Then close
	queue_free()

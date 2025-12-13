extends Node2D

const Constants = preload("res://src/Scripts/Constants.gd")
const TooltipScript = preload("res://src/Scripts/UI/Tooltip.gd")
const ProjectileScript = preload("res://src/Scripts/Projectile.gd")

var tooltip_ui: Control = null
var units_container: Node2D = null

func _ready():
	print("Running TestAnimalTheme...")

	# Create Tooltip instance manually since we don't have a scene running
	print("Tooltip scene not found, creating manually...")
	tooltip_ui = PanelContainer.new()
	tooltip_ui.set_script(TooltipScript)
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	tooltip_ui.add_child(vbox)
	var title = RichTextLabel.new()
	title.name = "TitleLabel"
	vbox.add_child(title)
	var stats = RichTextLabel.new()
	stats.name = "StatsLabel"
	vbox.add_child(stats)
	var buff = RichTextLabel.new()
	buff.name = "BuffLabel"
	vbox.add_child(buff)
	add_child(tooltip_ui)

	# Trigger ready manually since we just added it and want to use it immediately in same frame logic if needed
	# But normally add_child triggers it.

	test_unit_creation()
	test_tooltip_logic()
	print("TestAnimalTheme Completed.")
	get_tree().quit()

func test_unit_creation():
	print("--- Testing Unit Creation ---")
	var animal_units = ["squirrel", "octopus", "bee", "eel", "lion", "dragon", "dog", "butterfly"]

	for unit_id in animal_units:
		if unit_id in Constants.UNIT_TYPES:
			var data = Constants.UNIT_TYPES[unit_id]
			print("Unit Found: %s (%s) - Icon: %s" % [data.name, unit_id, data.icon])

			# Verify projectile type if applicable
			if data.has("proj"):
				print("  Projectile: %s" % data.proj)
		else:
			push_error("Unit not found: %s" % unit_id)

	# Verify deletions
	var deleted_units = ["turtle", "treant", "hydra", "crystal", "prism", "lens"]
	for unit_id in deleted_units:
		if unit_id in Constants.UNIT_TYPES:
			push_error("Unit should be deleted but exists: %s" % unit_id)
		else:
			print("Unit correctly deleted: %s" % unit_id)

func test_tooltip_logic():
	print("--- Testing Tooltip Logic ---")

	# 1. Test Attack Unit (Squirrel)
	var squirrel_data = Constants.UNIT_TYPES["squirrel"]
	var squirrel_stats = {
		"damage": squirrel_data.damage,
		"atk_speed": squirrel_data.atkSpeed,
		"range": squirrel_data.range,
		"crit_rate": squirrel_data.crit_rate,
		"crit_dmg": squirrel_data.crit_dmg
	}

	tooltip_ui.show_tooltip(squirrel_data, squirrel_stats, [], Vector2(100, 100))
	var text = tooltip_ui.stats_label.text
	if "⚔️" in text:
		print("Squirrel tooltip shows damage (Correct).")
	else:
		push_error("Squirrel tooltip MISSING damage!")

	# 2. Test Plant (Sunflower) - Should NOT show damage
	var plant_data = Constants.UNIT_TYPES["plant"]
	var plant_stats = {
		"damage": plant_data.damage,
		"atk_speed": plant_data.atkSpeed,
		"range": plant_data.range,
		"crit_rate": plant_data.crit_rate,
		"crit_dmg": plant_data.crit_dmg
	}

	tooltip_ui.show_tooltip(plant_data, plant_stats, [], Vector2(300, 100))
	text = tooltip_ui.stats_label.text
	if "⚔️" in text:
		push_error("Plant tooltip SHOWS damage (Incorrect)!")
	else:
		print("Plant tooltip hides damage (Correct).")

	# 3. Test Lion (Cannon replacement)
	var lion_data = Constants.UNIT_TYPES["lion"]
	print("Lion Desc: %s" % lion_data.desc)

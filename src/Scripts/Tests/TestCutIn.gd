extends Node

func _ready():
	# 1. Instantiate Manager
	var manager_scene = load("res://src/Scenes/UI/Effects/CutInManager.tscn")
	if not manager_scene:
		push_error("FAIL: CutInManager.tscn not found.")
		return
	var manager = manager_scene.instantiate()
	# Manager is anchor based, so we need to add it to a Control to test positioning well, or just add to root
	# If added to root (Node), Control features might act weird if not in a viewport with UI.
	# But we can still test logic.
	add_child(manager)

	# 2. Test Trigger
	print("Testing CutIn Trigger...")
	var mock_unit = {
		"name": "TestUnit",
		"skill": "Fireball",
		"type_key": "squirrel",
		"color": Color.RED,
		"unit_data": {"skill": "Fireball", "color": Color.RED, "type_key": "squirrel"}
	}
	manager.trigger_cutin(mock_unit)

	await get_tree().create_timer(0.1).timeout

	# Verify child exists
	if manager.get_child_count() == 1:
		print("PASS: CutInItem instantiated.")
		var item = manager.get_child(0)
		# Verify width (CutInItem custom_minimum_size)
		if item.custom_minimum_size.x >= 250 and item.custom_minimum_size.x <= 300:
			print("PASS: Width is aligned with Resource Bars (approx 270px).")
		else:
			print("WARN: Width might be misaligned. Current: ", item.custom_minimum_size.x)
	else:
		push_error("FAIL: CutInItem not created.")

	# 3. Test Stacking
	print("Testing Stacking...")
	manager.trigger_cutin(mock_unit) # Second item
	await get_tree().create_timer(0.4).timeout # Wait for tween

	var items = manager.get_children()
	# items[0] is the old one, items[1] is the new one.
	# But typically get_children returns in order of addition.
	# The manager adds new child using add_child(), so it's at end of list.
	# The loop in Manager iterates children.

	# Let's verify positions.
	# New item (items[1]) should be at (0,0) (or close to it)
	# Old item (items[0]) should have been moved UP (negative Y).

	if items.size() >= 2:
		var old_item = items[0]
		var new_item = items[1]
		print("Old Item Y: ", old_item.position.y)
		print("New Item Y: ", new_item.position.y)

		if old_item.position.y < new_item.position.y:
			print("PASS: Stacking order correct (Old item moved up).")
		else:
			push_error("FAIL: Stacking logic incorrect. Positions: " + str(old_item.position) + " vs " + str(new_item.position))
	else:
		push_error("FAIL: Second item not created.")

	print("CutIn Tests Completed.")
	get_tree().quit()

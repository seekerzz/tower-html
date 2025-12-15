extends Control

const CutInItemScene = preload("res://src/Scenes/UI/Effects/CutInItem.tscn")
const ITEM_HEIGHT = 120.0
const MAX_ITEMS = 3

func trigger_cutin(unit_data):
	var item = CutInItemScene.instantiate()
	add_child(item)
	item.setup(unit_data)

	# New item starts at (0, 0) (or relative to container)
	item.position = Vector2(0, 0)

	# Stack existing items upwards
	var children = get_children()
	# We iterate backwards or just filter for CutInItems
	var active_items = []
	for child in children:
		if child == item: continue
		if child.has_method("animate_exit"): # Check if it's a CutInItem
			active_items.append(child)

	# Sort by Y position (descending/ascending?)
	# Actually, we just need to move all EXISTING items up by ITEM_HEIGHT
	for existing_item in active_items:
		var target_y = existing_item.position.y - ITEM_HEIGHT
		var tween = create_tween()
		tween.tween_property(existing_item, "position:y", target_y, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Cleanup old items if too many
	if active_items.size() >= MAX_ITEMS:
		var oldest_item = active_items[0] # Assuming first child is oldest usually?
		# Actually get_children returns in order of addition.
		# So active_items[0] is the oldest.
		oldest_item.animate_exit()

	# Auto remove after some time
	if is_inside_tree():
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(item):
				item.animate_exit()
		)

extends Control

const CutInItemScene = preload("res://src/Scenes/UI/Effects/CutInItem.tscn")
const ITEM_HEIGHT = 120.0
const MAX_ITEMS = 3

var available_height: float = 500.0

func trigger_cutin(unit_data):
	var item = CutInItemScene.instantiate()
	add_child(item)
	item.setup(unit_data)
	item.position = Vector2(0, 0)

	# Get all valid items
	var all_items = []
	for child in get_children():
		if child.has_method("animate_exit") and not child.is_queued_for_deletion():
			all_items.append(child)

	# Handle MAX_ITEMS
	# We want to keep at most MAX_ITEMS.
	# The oldest ones should be removed.
	# all_items is sorted by age (oldest first).

	var items_to_keep = []
	var items_to_remove = []

	if all_items.size() > MAX_ITEMS:
		var remove_count = all_items.size() - MAX_ITEMS
		for i in range(remove_count):
			items_to_remove.append(all_items[i])
		for i in range(remove_count, all_items.size()):
			items_to_keep.append(all_items[i])
	else:
		items_to_keep = all_items.duplicate()

	# Animate removal
	for it in items_to_remove:
		it.animate_exit()

	# Layout kept items
	var count = items_to_keep.size()
	var spacing = ITEM_HEIGHT

	if count > 1:
		# The stack extends upwards. Newest is at 0.
		# Oldest is at -(count-1)*spacing.
		# We need (count-1)*spacing <= available_height
		var total_needed = (count - 1) * ITEM_HEIGHT
		if total_needed > available_height and available_height > 0:
			spacing = available_height / (count - 1)

	for i in range(count):
		var it = items_to_keep[i]
		# items_to_keep: [oldest, ..., newest]
		# newest (index count-1) -> pos 0
		# oldest (index 0) -> pos -(count-1)*spacing

		var reverse_index = count - 1 - i
		var target_y = -reverse_index * spacing

		if it == item:
			it.position.y = target_y
		else:
			var tween = create_tween()
			tween.tween_property(it, "position:y", target_y, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Auto remove after some time
	if is_inside_tree():
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(item):
				item.animate_exit()
		)

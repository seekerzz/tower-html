extends Control

const CutInItemScene = preload("res://src/Scenes/UI/Effects/CutInItem.tscn")

func trigger_cutin(unit):
	var item = CutInItemScene.instantiate()
	add_child(item)

	# Position new item at bottom (0,0 relative to container, assuming container is bottom-left aligned upwards or we manage positions)
	# The plan says: "Stacking logic: traverse current active items, move their position.y up by item height (-120px)."
	# "New item at 0,0 or bottom".

	# If the container is anchored at Bottom-Left, (0,0) is top-left of the container.
	# If we want items to stack upwards from bottom, we should anchor the container such that (0,0) is where the newest item appears?
	# Or we just manually position them.

	# Let's say new item is at (0, 0). Previous items need to move up (negative Y).
	item.position = Vector2(0, 0)

	# Setup content
	item.setup(unit)

	# Stack existing items
	for child in get_children():
		if child == item: continue
		if child.is_queued_for_deletion(): continue

		var target_y = child.position.y - 125.0 # 120 height + 5 margin
		var tween = create_tween()
		tween.tween_property(child, "position:y", target_y, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

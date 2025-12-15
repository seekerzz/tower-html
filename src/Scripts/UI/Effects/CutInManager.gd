extends Control

const CutInItemScene = preload("res://src/Scenes/UI/Effects/CutInItem.tscn")
const ITEM_HEIGHT = 120.0
const MAX_ITEMS = 3

var available_height: float = 500.0
var cutin_items: Array[Control] = []

func _process(delta):
	_update_item_positions(delta)

func set_available_height(h: float):
	available_height = h

func trigger_cutin(unit_data):
	var item = CutInItemScene.instantiate()
	add_child(item)
	item.setup(unit_data)

	# New item starts at (0, 0)
	item.position = Vector2(0, 0)

	# Add to list
	cutin_items.push_front(item)

	# Cleanup old items if too many
	if cutin_items.size() > MAX_ITEMS:
		var oldest_item = cutin_items.pop_back()
		if is_instance_valid(oldest_item):
			oldest_item.animate_exit()

	# Auto remove after some time
	if is_inside_tree():
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(item) and item in cutin_items:
				# Remove from list so it stops being positioned
				cutin_items.erase(item)
				item.animate_exit()
		)

func _update_item_positions(delta):
	var count = cutin_items.size()
	if count <= 1:
		# Just one item (or none), no stacking needed relative to others
		# But we still want to ensure it is at 0 if it's the only one?
		# Actually, new item is at 0.
		# If we have 1 item, index 0. target = 0.
		if count == 1:
			var item = cutin_items[0]
			if is_instance_valid(item):
				# Interpolate to 0
				item.position.y = lerp(item.position.y, 0.0, 10 * delta)
		return

	# Calculate spacing
	# We want the top of the oldest item (index N-1) to be within available_height.
	# The oldest item is at position -(N-1)*spacing.
	# So (N-1)*spacing <= available_height.
	var spacing = ITEM_HEIGHT
	if (count - 1) * spacing > available_height:
		spacing = available_height / float(count - 1)

	# Clamp spacing to be reasonably visible (optional, but good)
	# But user requirement says "stacking distance depends on ... area remaining"
	# So we allow it to shrink.

	for i in range(count):
		var item = cutin_items[i]
		if not is_instance_valid(item):
			continue

		var target_y = -float(i) * spacing

		# Smoothly move to target
		item.position.y = lerp(item.position.y, target_y, 10 * delta)

extends Control

@onready var slots_container = $PanelContainer/SlotsContainer

func _ready():
	if slots_container:
		slots_container.add_theme_constant_override("h_separation", 10)
		slots_container.add_theme_constant_override("v_separation", 10)

		# Create 8 slots
		for i in range(8):
			_create_slot(i)

	connect_signals()

func connect_signals():
	# Connect to inventory manager if available
	if "inventory_manager" in GameManager and GameManager.inventory_manager:
		if GameManager.inventory_manager.has_signal("inventory_updated"):
			if !GameManager.inventory_manager.inventory_updated.is_connected(_on_inventory_updated):
				GameManager.inventory_manager.inventory_updated.connect(_on_inventory_updated)
			# Initial update if method exists
			if GameManager.inventory_manager.has_method("get_inventory"):
				_on_inventory_updated(GameManager.inventory_manager.get_inventory())

func _create_slot(index):
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(60, 60)
	slot.name = "Slot_%d" % index

	# Background Panel
	var panel = Panel.new()
	panel.layout_mode = 1
	panel.anchors_preset = 15
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)

	slot.add_child(panel)
	slots_container.add_child(slot)

func _on_inventory_updated(data):
	# data is assumed to be an Array of items
	# Clear contents only (not slots themselves as they are fixed 8)
	for i in range(slots_container.get_child_count()):
		var slot = slots_container.get_child(i)
		# Clear previous content (anything that is NOT the bg panel)
		for child in slot.get_children():
			if child is Panel: continue
			slot.remove_child(child)
			child.queue_free()

		if i < data.size() and data[i] != null:
			var item = data[i]
			_add_item_to_slot(slot, item)

func _add_item_to_slot(slot, item):
	# Icon
	var icon = TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.layout_mode = 1
	icon.anchors_preset = 15
	icon.offset_left = 5
	icon.offset_top = 5
	icon.offset_right = -5
	icon.offset_bottom = -5
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Handle icon source
	if item.has("icon") and item.icon:
		icon.texture = item.icon
	elif item.has("icon_path") and item.icon_path:
		icon.texture = load(item.icon_path)
	elif item.has("id"):
		var tex = AssetLoader.get_item_icon(item.id)
		if tex:
			icon.texture = tex

	slot.add_child(icon)

	# Count
	if item.has("count") and item.count > 1:
		var lbl = Label.new()
		lbl.text = str(item.count)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lbl.layout_mode = 1
		lbl.anchors_preset = 15
		lbl.offset_right = -5
		lbl.offset_bottom = -2
		lbl.add_theme_font_size_override("font_size", 12)
		slot.add_child(lbl)

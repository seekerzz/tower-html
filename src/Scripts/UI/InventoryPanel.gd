extends Control

const SLOT_COUNT = 8

@onready var slots_container = $PanelContainer/SlotsContainer

func _ready():
	if slots_container:
		slots_container.add_theme_constant_override("h_separation", 10)
		slots_container.add_theme_constant_override("v_separation", 10)
		var parent = slots_container.get_parent()
		if parent is PanelContainer:
			var style = StyleBoxEmpty.new()
			parent.add_theme_stylebox_override("panel", style)

	_init_slots()

	# Assuming GameManager has an inventory_manager property as per instructions
	if GameManager.get("inventory_manager") and GameManager.inventory_manager:
		if !GameManager.inventory_manager.is_connected("inventory_updated", update_inventory):
			GameManager.inventory_manager.connect("inventory_updated", update_inventory)
		# Initial update if data exists
		if GameManager.inventory_manager.has_method("get_inventory"):
			update_inventory(GameManager.inventory_manager.get_inventory())

func _init_slots():
	# Clear existing
	for child in slots_container.get_children():
		child.queue_free()

	for i in range(SLOT_COUNT):
		var slot = Control.new()
		slot.custom_minimum_size = Vector2(60, 60)
		slot.name = "Slot_%d" % i

		# Background Style
		var panel = Panel.new()
		panel.layout_mode = 1
		panel.anchors_preset = 15
		panel.mouse_filter = MOUSE_FILTER_IGNORE

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 1)
		style.set_corner_radius_all(8)

		panel.add_theme_stylebox_override("panel", style)
		slot.add_child(panel)

		slots_container.add_child(slot)

func update_inventory(data: Array):
	if !slots_container: return

	var slots = slots_container.get_children()
	for i in range(slots.size()):
		var slot = slots[i]
		# Clear previous content (except the background panel)
		for child in slot.get_children():
			if child is Panel: continue
			child.queue_free()

		if i < data.size() and data[i] != null:
			var item = data[i]
			# Create Icon
			var icon_rect = TextureRect.new()
			# Assuming item has an 'id' property
			var icon = AssetLoader.get_item_icon(item.id) if item.has("id") else null
			if icon:
				icon_rect.texture = icon
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.layout_mode = 1
			icon_rect.anchors_preset = 15
			# Add some padding
			icon_rect.offset_left = 5
			icon_rect.offset_top = 5
			icon_rect.offset_right = -5
			icon_rect.offset_bottom = -5

			# Attach Drag Handler
			var drag_handler = Control.new()
			drag_handler.set_script(load("res://src/Scripts/UI/ItemDragHandler.gd"))
			drag_handler.layout_mode = 1
			drag_handler.anchors_preset = 15
			drag_handler.mouse_filter = MOUSE_FILTER_STOP
			drag_handler.setup(i, item, icon_rect.texture)
			icon_rect.add_child(drag_handler)

			# Ensure icon_rect can receive mouse so children can too?
			# Actually TextureRect defaults to IGNORE.
			# If we add drag_handler (Control STOP) as child, drag_handler will catch it if icon_rect is IGNORE?
			# No, if parent is IGNORE, children still get events if they are inside rect.
			# But safer to set icon_rect to PASS or IGNORE.
			# If icon_rect is IGNORE, drag_handler (STOP) works fine.

			slot.add_child(icon_rect)

			# Count
			if item.get("count", 0) > 1:
				var count_lbl = Label.new()
				count_lbl.text = str(item.count)
				count_lbl.add_theme_font_size_override("font_size", 14)
				count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
				count_lbl.layout_mode = 1
				count_lbl.anchors_preset = 15
				count_lbl.offset_right = -4
				count_lbl.offset_bottom = 0
				slot.add_child(count_lbl)

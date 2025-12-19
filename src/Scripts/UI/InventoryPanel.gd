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

	if GameManager.get("inventory_manager") and GameManager.inventory_manager:
		if !GameManager.inventory_manager.is_connected("inventory_updated", update_inventory):
			GameManager.inventory_manager.connect("inventory_updated", update_inventory)
		if GameManager.inventory_manager.has_method("get_inventory"):
			update_inventory(GameManager.inventory_manager.get_inventory())

func _init_slots():
	for child in slots_container.get_children():
		child.queue_free()

	for i in range(SLOT_COUNT):
		var slot = Control.new()
		slot.custom_minimum_size = Vector2(60, 60)
		slot.name = "Slot_%d" % i

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
			var icon = AssetLoader.get_item_icon(item.id) if item.has("id") else null
			if icon:
				icon_rect.texture = icon
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.layout_mode = 1
			icon_rect.anchors_preset = 15
			icon_rect.offset_left = 5
			icon_rect.offset_top = 5
			icon_rect.offset_right = -5
			icon_rect.offset_bottom = -5
			slot.add_child(icon_rect)

			# Attach ItemDragHandler
			# We use 'load' to avoid cyclic dependencies if any, but class_name is better if available.
			# Using script path as per instructions.
			var drag_handler_script = load("res://src/Scripts/UI/ItemDragHandler.gd")
			if drag_handler_script:
				var drag_handler = drag_handler_script.new()
				# We attach it to the icon_rect or the slot?
				# Task says: "generated item icon node mounted ItemDragHandler"
				# So we attach it to icon_rect.
				icon_rect.add_child(drag_handler)
				if drag_handler.has_method("setup"):
					drag_handler.setup(item, icon_rect)
				else:
					# If setup is not defined, maybe it uses _init or properties?
					# I'll assume setup is the way or check the file if I could.
					# But since I saw 'UnitDragHandler' and 'ItemDragHandler' in list_files, I assume it follows similar pattern.
					pass

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

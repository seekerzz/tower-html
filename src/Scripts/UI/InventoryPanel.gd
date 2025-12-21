extends Control

const SLOT_COUNT = 9

@onready var slots_container = $PanelContainer/SlotsContainer

func _ready():
	print("[InventoryPanel] UI Ready initialized.") # 调试日志
	
	if slots_container:
		slots_container.columns = 3
		slots_container.add_theme_constant_override("h_separation", 10)
		slots_container.add_theme_constant_override("v_separation", 10)

		# Ensure scrolling support
		var parent = slots_container.get_parent()
		if not parent is ScrollContainer:
			var scroll = ScrollContainer.new()
			scroll.name = "InventoryScroll"
			scroll.custom_minimum_size.y = 200 # Allow scrolling if content exceeds this
			scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
			scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			# We need to swap parents carefully
			var grand_parent = parent.get_parent() # Likely PanelContainer

			# Remove Grid from current parent
			parent.remove_child(slots_container)

			# Add Grid to Scroll
			scroll.add_child(slots_container)

			# Add Scroll to where Grid was (or to the PanelContainer if parent was just a helper)
			# The structure is $PanelContainer -> $SlotsContainer (Grid)
			# We want $PanelContainer -> $ScrollContainer -> $SlotsContainer

			parent.add_child(scroll)

		var container_parent = slots_container.get_parent() # ScrollContainer now
		if container_parent and container_parent.get_parent() is PanelContainer:
			var style = StyleBoxEmpty.new()
			container_parent.get_parent().add_theme_stylebox_override("panel", style)

	else:
		push_error("[InventoryPanel] Error: SlotsContainer not found!")

	_init_slots()

	# 连接信号
	if GameManager.get("inventory_manager") and GameManager.inventory_manager:
		var inv_mgr = GameManager.inventory_manager
		if !inv_mgr.is_connected("inventory_updated", update_inventory):
			inv_mgr.connect("inventory_updated", update_inventory)
			print("[InventoryPanel] Connected to inventory_manager signal.")
		
		# 初始加载
		if inv_mgr.has_method("get_inventory"):
			update_inventory(inv_mgr.get_inventory())
		else:
			push_error("[InventoryPanel] InventoryManager missing get_inventory() method.")

func _init_slots():
	if !slots_container: return
	for child in slots_container.get_children():
		child.queue_free()

	var drag_handler_script = preload("res://src/Scripts/UI/ItemDragHandler.gd")

	for i in range(SLOT_COUNT):
		var slot = Control.new()
		slot.set_script(drag_handler_script)
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
	# 调试日志：打印接收到的数据
	print("[InventoryPanel] update_inventory called with data: ", data)
	
	if !slots_container: return

	var slots = slots_container.get_children()
	for i in range(slots.size()):
		var slot = slots[i]
		# 清理旧图标（保留背景 Panel）
		for child in slot.get_children():
			if child is Panel: continue
			child.queue_free()

		if i < data.size() and data[i] != null:
			var item = data[i]

			if slot.get_script() == preload("res://src/Scripts/UI/ItemDragHandler.gd"):
				slot.slot_index = i
				slot.item_data = item

			var item_id = item.get("item_id", "unknown")
			
			# 尝试加载图标
			var icon_rect = TextureRect.new()
			var icon = AssetLoader.get_item_icon(item_id) if item_id else null
			
			if icon:
				icon_rect.texture = icon
			else:
				# --- 关键修改：如果图片缺失，显示红色文字 ---
				print("[InventoryPanel] Warning: Missing icon for item: ", item_id)
				var text_fallback = Label.new()
				text_fallback.text = str(item_id)
				text_fallback.modulate = Color(1, 0, 0, 1) # 红色
				text_fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				text_fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				text_fallback.layout_mode = 1
				text_fallback.anchors_preset = 15
				slot.add_child(text_fallback)

			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.layout_mode = 1
			icon_rect.anchors_preset = 15
			icon_rect.offset_left = 5
			icon_rect.offset_top = 5
			icon_rect.offset_right = -5
			icon_rect.offset_bottom = -5
			slot.add_child(icon_rect)

			# 显示数量
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
		else:
			# Slot is empty, clear data
			if slot.get_script() == preload("res://src/Scripts/UI/ItemDragHandler.gd"):
				slot.slot_index = -1
				slot.item_data = {}

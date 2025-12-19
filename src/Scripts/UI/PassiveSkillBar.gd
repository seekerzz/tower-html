extends Control

@onready var container = $PanelContainer/GridContainer

func _ready():
	if container:
		container.add_theme_constant_override("h_separation", 10)
		container.add_theme_constant_override("v_separation", 10)

		# Make background transparent/empty for container parent if needed
		var parent = container.get_parent()
		if parent is PanelContainer:
			var style = StyleBoxEmpty.new()
			parent.add_theme_stylebox_override("panel", style)

func _process(_delta):
	# Refresh units every frame as requested
	# Ideally we should use signals, but task says "Every frame (or signal)" and "monitor all viper and scorpion"

	var units = []
	if GameManager.grid_manager and GameManager.grid_manager.tiles:
		for key in GameManager.grid_manager.tiles:
			var tile = GameManager.grid_manager.tiles[key]
			if tile.unit:
				var type = ""
				if tile.unit.has_method("get_type"):
					type = tile.unit.get_type()
				elif "type_key" in tile.unit:
					type = tile.unit.type_key
				elif "unit_data" in tile.unit and tile.unit.unit_data.has("id"):
					type = tile.unit.unit_data.id

				# Check for viper and scorpion (simple string check)
				if "viper" in type or "scorpion" in type:
					units.append(tile.unit)

	# Sync UI count with units count
	if units.size() != container.get_child_count():
		_rebuild_ui(units)
	else:
		_update_ui_func(units)

func _update_ui_func(units):
	for i in range(units.size()):
		var card = container.get_child(i)
		var unit = units[i]
		_update_card(card, unit)

func _rebuild_ui(units):
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

	for unit in units:
		var card = PanelContainer.new()
		# Match SkillBar size roughly
		card.custom_minimum_size = Vector2(60, 80)

		var style = StyleBoxFlat.new()
		style.bg_color = Color("#2c3e50")
		style.border_color = Color("#3498db")
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		card.add_theme_stylebox_override("panel", style)

		var layout = Control.new()
		layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(layout)

		# Icon
		var icon = TextureRect.new()
		icon.name = "Icon"
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.layout_mode = 1
		icon.anchors_preset = 15
		icon.offset_left = 5
		icon.offset_top = 5
		icon.offset_right = -5
		icon.offset_bottom = -5
		layout.add_child(icon)

		# CD Mask
		var cd = TextureProgressBar.new()
		cd.name = "CD_Mask"
		cd.fill_mode = TextureProgressBar.FILL_CLOCKWISE
		cd.nine_patch_stretch = true
		cd.layout_mode = 1
		cd.anchors_preset = 15
		cd.tint_progress = Color(0, 0, 0, 0.7)

		# White pixel texture
		var img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		cd.texture_progress = ImageTexture.create_from_image(img)

		layout.add_child(cd)

		container.add_child(card)

		# Initial Update
		_update_card(card, unit)

func _update_card(card, unit):
	var layout = card.get_child(0)
	var cd = layout.get_node("CD_Mask")
	var icon = layout.get_node("Icon")
	var style = card.get_theme_stylebox("panel")

	# Update Icon
	var type_key = "viper" # default
	if "type_key" in unit: type_key = unit.type_key

	# Safe AssetLoader usage
	# AssetLoader is a static class (class_name) so we can check if it exists in scope or just call it if we trust the environment.
	# Since it is a class_name, 'AssetLoader' is a GDScriptNativeClass or similar.
	# We can just call it, but if we want to be safe against missing class in isolated tests:
	# Note: TestNewUI will fail if AssetLoader is missing.

	# Ideally we assume AssetLoader exists as it's part of the codebase.
	var tex = AssetLoader.get_unit_icon(type_key)
	if tex and icon.texture != tex:
		icon.texture = tex

	# production_timer binding
	if "production_timer" in unit:
		var timer = unit.production_timer # Assuming it's a Timer node
		if timer and !timer.is_stopped():
			cd.max_value = timer.wait_time
			cd.value = timer.time_left

			# Check for flash animation condition (e.g. just restarted)
			# We can simulate flash by changing border color briefly if value is very close to max
			if cd.value > cd.max_value - 0.1:
				if style is StyleBoxFlat:
					style.border_color = Color.WHITE # Flash white
			else:
				if style is StyleBoxFlat:
					style.border_color = Color("#3498db") # Reset blue
		else:
			cd.value = 0

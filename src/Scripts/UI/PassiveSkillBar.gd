extends Control

@onready var container = $PanelContainer/GridContainer
@onready var panel_container = $PanelContainer

var monitored_units = []

func _ready():
	# Ensure the container is set up correctly
	if container:
		# We want a VBoxContainer instead of GridContainer for row-based management
		# But since the node is in the scene tree as GridContainer, we swap it programmatically if needed.
		if container is GridContainer:
			var parent = container.get_parent()
			container.name = "OldGrid"
			container.queue_free()

			container = VBoxContainer.new()
			container.name = "RowsContainer"
			container.add_theme_constant_override("separation", 5) # Spacing between rows
			parent.add_child(container)

		var parent = container.get_parent()
		if parent is PanelContainer:
			var style = StyleBoxEmpty.new()
			parent.add_theme_stylebox_override("panel", style)

	refresh_units()

	# Connect to grid updates
	if GameManager.grid_manager and GameManager.grid_manager.has_signal("grid_updated"):
		if !GameManager.grid_manager.is_connected("grid_updated", refresh_units):
			GameManager.grid_manager.grid_updated.connect(refresh_units)

func refresh_units():
	# Scan for viper and scorpion units on the grid
	monitored_units.clear()

	# Clear UI
	for child in container.get_children():
		child.queue_free()

	if !GameManager.grid_manager: return

	# Assuming GridManager has tiles dict
	var tiles = GameManager.grid_manager.tiles
	var found_units = []
	for key in tiles:
		var tile = tiles[key]
		if tile.unit:
			var u = tile.unit
			if u.type_key == "viper" or u.type_key == "scorpion":
				found_units.append(u)
				monitored_units.append(u)

	# Layout Logic: Rows of 3.
	# "Add new row above... adding new skills there"
	# Chunk 0 (indices 0,1,2), Chunk 1 (indices 3,4,5)...
	# Chunk N (Newest) should be at Top (Index 0 in VBox).
	# So we reverse the chunks.

	var chunks = []
	var current_chunk = []
	for i in range(found_units.size()):
		current_chunk.append(found_units[i])
		if current_chunk.size() == 3:
			chunks.append(current_chunk)
			current_chunk = []

	if current_chunk.size() > 0:
		chunks.append(current_chunk)

	# Add rows in reverse order (Newest chunks first)
	chunks.reverse()

	for chunk in chunks:
		var row = HBoxContainer.new()
		# Align Center or consistent with Inventory? Inventory is 3 slots wide.
		# If we align Center, they stack nicely.
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10) # Match horizontal separation

		for unit in chunk:
			_create_card_in_row(unit, row)

		container.add_child(row)

func _create_card_in_row(unit, parent_row):
	var card = PanelContainer.new()
	# Size Flags: If we want them fixed size, we set custom min size and no expansion.
	# But Inventory slots are 60x60. Passive are 45x45.
	card.custom_minimum_size = Vector2(45, 60) # 45 wide, 60 tall (container height) or just square
	# Using 60 height for consistent row height
	card.name = "PassiveCard_%s" % unit.name

	# Meta for Logic
	card.set_meta("unit_ref", unit)

	# Style matching SkillBar
	var bg_color = Color("#2c3e50")
	var style = StyleMaker.get_flat_style(bg_color, 8, 2, Color("#3498db"))
	card.add_theme_stylebox_override("panel", style)

	# Layout
	var layout = Control.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(layout)

	# Icon
	var icon_tex = AssetLoader.get_unit_icon(unit.type_key)
	var icon_rect = TextureRect.new()
	if icon_tex:
		icon_rect.texture = icon_tex
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Updated: Smaller Square 45x45
	var size = 45
	icon_rect.custom_minimum_size = Vector2(size, size)
	icon_rect.size = Vector2(size, size)
	var offset = size / 2.0
	icon_rect.offset_left = -offset
	icon_rect.offset_top = -offset
	icon_rect.offset_right = offset
	icon_rect.offset_bottom = offset
	layout.add_child(icon_rect)

	# CD Overlay
	var cd_bar = TextureProgressBar.new()
	cd_bar.name = "CD_Overlay"
	cd_bar.nine_patch_stretch = true
	cd_bar.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	cd_bar.value = 0
	cd_bar.max_value = 1.0
	cd_bar.step = 0.01
	cd_bar.tint_progress = Color(0, 0, 0, 0.7)
	cd_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cd_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var placeholder = ImageTexture.create_from_image(img)
	cd_bar.texture_progress = placeholder

	layout.add_child(cd_bar)

	# White Flash Overlay
	var flash_overlay = ColorRect.new()
	flash_overlay.name = "FlashOverlay"
	flash_overlay.color = Color.WHITE
	flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_overlay.modulate.a = 0.0 # Invisible start
	layout.add_child(flash_overlay)

	parent_row.add_child(card)

func _process(_delta):
	# Resize Logic: Ensure this Control reports size matching content
	if panel_container:
		var target = panel_container.get_combined_minimum_size()
		if custom_minimum_size != target:
			custom_minimum_size = target

	# Update CD overlays and handle flashing
	# Iterate Rows
	var rows = container.get_children()

	for row in rows:
		if not row is HBoxContainer: continue
		for card in row.get_children():
			var unit = card.get_meta("unit_ref", null)
			if !is_instance_valid(unit):
				continue

			var layout = card.get_child(0)
			var cd_bar = layout.get_node("CD_Overlay")
			var flash = layout.get_node("FlashOverlay")

			var prev_timer = card.get_meta("prev_timer", 0.0)
			var current_timer = unit.production_timer

			if prev_timer > 0 and current_timer <= 0:
				_trigger_flash(flash)
			elif prev_timer > 0 and current_timer > prev_timer:
				_trigger_flash(flash)

			card.set_meta("prev_timer", current_timer)

			cd_bar.max_value = unit.max_production_timer
			cd_bar.value = unit.production_timer

func _trigger_flash(overlay):
	if !overlay.has_meta("flashing") or !overlay.get_meta("flashing"):
		overlay.set_meta("flashing", true)
		var tween = create_tween()
		# Flash White (Alpha 0 -> 0.8 -> 0)
		tween.tween_property(overlay, "modulate:a", 0.8, 0.1).set_trans(Tween.TRANS_SINE)
		tween.tween_property(overlay, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
		tween.finished.connect(func(): overlay.set_meta("flashing", false))

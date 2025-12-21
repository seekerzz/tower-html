extends Control

var container: VBoxContainer
@onready var panel_container = $PanelContainer

var monitored_units = []

func _ready():
	# Dynamically replace GridContainer with VBoxContainer for Row-based layout
	var old_grid = panel_container.get_node_or_null("GridContainer")
	if old_grid:
		old_grid.queue_free()

	container = VBoxContainer.new()
	container.name = "RowsContainer"
	# Compact spacing between rows
	container.add_theme_constant_override("separation", 10)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_SHRINK_END # Pack at bottom

	panel_container.add_child(container)

	if panel_container:
		var style = StyleBoxEmpty.new()
		panel_container.add_theme_stylebox_override("panel", style)

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
	# Collect all valid passive units first
	for key in tiles:
		var tile = tiles[key]
		if tile.unit:
			var u = tile.unit
			if u.type_key == "viper" or u.type_key == "scorpion":
				monitored_units.append(u)

	# Create Rows (Chunks of 3)
	# Requirement: "Add a new row above the existing row".
	# Logic: Chunk 0 (Oldest) -> Bottom. Chunk N (Newest) -> Top.
	# Implementation: Create rows in order 0..N, and move each new row to index 0 of the VBox.
	# This stacks them: Row N, ..., Row 1, Row 0.

	var chunk_size = 3
	var current_row: HBoxContainer = null

	for i in range(monitored_units.size()):
		if i % chunk_size == 0:
			# Start new row
			current_row = HBoxContainer.new()
			current_row.name = "Row_%d" % (i / chunk_size)
			current_row.add_theme_constant_override("separation", 10)
			current_row.alignment = BoxContainer.ALIGNMENT_CENTER

			container.add_child(current_row)
			# Move to top to stack upwards
			container.move_child(current_row, 0)

		var unit = monitored_units[i]
		_create_card(unit, current_row)

func _create_card(unit, parent_row):
	var card = PanelContainer.new()
	# Fixed size for 1:1 look
	card.custom_minimum_size = Vector2(60, 60)
	card.name = "PassiveCard_%s" % unit.name

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

	# Smaller Square 45x45
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

	parent_row.add_child(card)

func _process(_delta):
	# Resize Logic: Ensure this Control reports size matching content
	if panel_container and container:
		# Calculate combined height of rows
		var target_height = 0.0
		for child in container.get_children():
			if child is Container:
				target_height += child.get_combined_minimum_size().y

		# Add separation
		var sep = container.get_theme_constant("separation")
		var visible_children = 0
		for c in container.get_children(): if c.visible: visible_children += 1
		if visible_children > 1:
			target_height += (visible_children - 1) * sep

		# Enforce minimum size on self so VBox parent respects it
		if custom_minimum_size.y != target_height:
			custom_minimum_size.y = target_height

	# Update CD overlays and handle flashing
	# Iterate rows, then cards
	if !container: return

	var unit_index = 0
	# Note: Rows are in reverse order visually (Child 0 is Top/Newest).
	# But we populated them by chunks.
	# Chunk 0 (Units 0,1,2) is at Index N (Bottom).
	# Chunk 1 (Units 3,4,5) is at Index N-1.
	# ...
	# Chunk M (Newest) is at Index 0.

	# We need to map cards back to monitored_units indices.
	# It's easier to just iterate the hierarchy and match against monitored_units sequentially?
	# No, because hierarchy is reversed in terms of chunks.
	# Chunk 0 has units 0,1,2. It is at the BOTTOM.
	# So we should iterate rows from Bottom (Last Child) to Top (First Child).

	var rows = container.get_children()
	# Reverse iteration to match unit order 0..N
	for r_i in range(rows.size() - 1, -1, -1):
		var row = rows[r_i]
		var cards = row.get_children()
		for card in cards:
			if unit_index >= monitored_units.size(): break

			var unit = monitored_units[unit_index]
			unit_index += 1

			if !is_instance_valid(unit):
				continue

			var layout = card.get_child(0)
			var cd_bar = layout.get_node("CD_Overlay")

			var prev_timer = card.get_meta("prev_timer", 0.0)
			var current_timer = unit.production_timer

			if prev_timer > 0 and current_timer <= 0:
				_trigger_flash(card)
			elif prev_timer > 0 and current_timer > prev_timer:
				_trigger_flash(card)

			card.set_meta("prev_timer", current_timer)

			cd_bar.max_value = unit.max_production_timer
			cd_bar.value = unit.production_timer

func _trigger_flash(card):
	if !card.has_meta("flashing") or !card.get_meta("flashing"):
		card.set_meta("flashing", true)
		var tween = create_tween()
		# High intensity white flash
		tween.tween_property(card, "modulate", Color(3.0, 3.0, 3.0), 0.15).set_trans(Tween.TRANS_SINE)
		tween.tween_property(card, "modulate", Color.WHITE, 0.15).set_trans(Tween.TRANS_SINE)
		tween.finished.connect(func(): card.set_meta("flashing", false))

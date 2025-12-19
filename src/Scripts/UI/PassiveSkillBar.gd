extends Control

@onready var container = $PanelContainer/GridContainer

var monitored_units = []

func _ready():
	# Ensure the container is set up correctly
	if container:
		container.add_theme_constant_override("h_separation", 10)
		container.add_theme_constant_override("v_separation", 10)
		var parent = container.get_parent()
		if parent is PanelContainer:
			var style = StyleBoxEmpty.new()
			parent.add_theme_stylebox_override("panel", style)

	# Use a timer to periodically scan for units instead of frame-by-frame if optimization is needed,
	# but _process is fine for UI updates.

	refresh_units()

	# Connect to grid updates if possible to refresh list less often
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
	for key in tiles:
		var tile = tiles[key]
		if tile.unit:
			var u = tile.unit
			if u.type_key == "viper" or u.type_key == "scorpion":
				monitored_units.append(u)
				_create_card(u)

func _create_card(unit):
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.y = 80
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
	icon_rect.custom_minimum_size = Vector2(50, 50)
	icon_rect.size = Vector2(50, 50)
	icon_rect.offset_left = -25
	icon_rect.offset_top = -25
	icon_rect.offset_right = 25
	icon_rect.offset_bottom = 25
	layout.add_child(icon_rect)

	# CD Overlay
	var cd_bar = TextureProgressBar.new()
	cd_bar.name = "CD_Overlay"
	cd_bar.nine_patch_stretch = true
	cd_bar.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	cd_bar.value = 0
	cd_bar.max_value = 1.0 # Will be updated
	cd_bar.step = 0.01
	cd_bar.tint_progress = Color(0, 0, 0, 0.7)
	cd_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cd_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var placeholder = ImageTexture.create_from_image(img)
	cd_bar.texture_progress = placeholder

	layout.add_child(cd_bar)

	container.add_child(card)

func _process(_delta):
	# Update CD overlays and handle flashing
	var children = container.get_children()
	for i in range(children.size()):
		if i >= monitored_units.size(): break

		var card = children[i]
		var unit = monitored_units[i]

		# Check if unit is still valid
		if !is_instance_valid(unit):
			card.queue_free()
			continue

		var layout = card.get_child(0)
		var cd_bar = layout.get_node("CD_Overlay")

		# Bind production_timer to CD overlay
		# production_timer goes from MAX down to 0
		# If unit has 'produce' logic, production_timer resets to 1.0 or similar.
		# Default logic in Unit.gd: production_timer -= delta. If <= 0, resets to 1.0.
		# So value is remaining time. Max value?
		# Usually it's hardcoded to 1.0 or 5.0 (for cow).
		# We need to know the max.

		cd_bar.max_value = unit.max_production_timer
		cd_bar.value = unit.production_timer

		# Flash animation
		if unit.production_timer <= 0.1: # Just finished or about to
			if !card.has_meta("flashing") or !card.get_meta("flashing"):
				card.set_meta("flashing", true)
				var tween = create_tween()
				tween.tween_property(card, "modulate", Color(1.5, 1.5, 1.5), 0.1)
				tween.tween_property(card, "modulate", Color.WHITE, 0.1)
				tween.finished.connect(func(): card.set_meta("flashing", false))

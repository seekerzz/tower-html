extends Control

@onready var container = $PanelContainer/GridContainer

var monitored_units = []

func _ready():
	if container:
		container.add_theme_constant_override("h_separation", 10)
		container.add_theme_constant_override("v_separation", 10)
		var parent = container.get_parent()
		if parent is PanelContainer:
			var style = StyleBoxEmpty.new()
			parent.add_theme_stylebox_override("panel", style)

	# Initial check
	_scan_units()

	# Listen for grid updates to rescan units
	if GameManager.grid_manager:
		if !GameManager.grid_manager.grid_updated.is_connected(_scan_units):
			GameManager.grid_manager.grid_updated.connect(_scan_units)

	# Also listen for unit purchases/sales
	GameManager.unit_purchased.connect(func(_u): _scan_units())
	GameManager.unit_sold.connect(func(_u): _scan_units())

func _process(_delta):
	# Update CD bars
	for i in range(monitored_units.size()):
		var unit = monitored_units[i]
		if i >= container.get_child_count(): break

		var card = container.get_child(i)
		var layout = card.get_child(0)
		var cd_bar = layout.get_node("CD_Overlay")

		if is_instance_valid(unit) and unit.has_method("get_production_progress"):
			var progress = unit.get_production_progress() # Expected 0.0 to 1.0 or similar
			# If unit doesn't have get_production_progress, we check production_timer

			# Assuming unit has `production_timer` node or property
			# Based on prompt: "绑定单位的 production_timer (生产倒计时) 到 CD 遮罩的 value"
			if unit.get("production_timer") and is_instance_valid(unit.production_timer):
				var timer = unit.production_timer
				if !timer.is_stopped():
					cd_bar.max_value = timer.wait_time
					cd_bar.value = timer.time_left
				else:
					cd_bar.value = 0

			# Check for flash condition (e.g. just finished)
			# This might need a signal or checking if value dropped to 0 recently.
			# For simplicity, if value is very close to 0 and was higher, or using a signal.
			# The prompt says: "当倒计时结束/生产触发时，播放简单的闪烁动画。"
			# We can connect to the timer's timeout signal if we can access it.
		else:
			# Mocking for generic units or removal
			pass

func _scan_units():
	if !container: return

	# Clear existing
	for child in container.get_children():
		child.queue_free()
	monitored_units.clear()

	if !GameManager.grid_manager: return

	# Scan for vipers and scorpions
	var relevant_units = []
	for key in GameManager.grid_manager.tiles:
		var tile = GameManager.grid_manager.tiles[key]
		if tile.unit:
			var u_key = tile.unit.type_key # e.g. "viper", "scorpion"
			if u_key == "viper" or u_key == "scorpion":
				relevant_units.append(tile.unit)

	monitored_units = relevant_units

	for i in range(monitored_units.size()):
		var unit = monitored_units[i]
		_create_card(unit, i)

		# Connect to timeout if possible for flash
		if unit.get("production_timer") and unit.production_timer.has_signal("timeout"):
			# Ensure we don't connect multiple times or with wrong bindings.
			# Disconnect if connected with old binding? Hard to check specifically.
			# Simpler: check if connected to the method with this unit bound?
			if !unit.production_timer.timeout.is_connected(_on_unit_produced.bind(unit)):
				unit.production_timer.timeout.connect(_on_unit_produced.bind(unit))

func _create_card(unit, index):
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.y = 80
	card.name = "PassiveCard_%d" % index

	# Style
	var bg_color = Color("#2c3e50")
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(8)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color("#3498db")

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
	cd_bar.max_value = 100 # Will be updated
	cd_bar.tint_progress = Color(0, 0, 0, 0.7)
	cd_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# White texture for progress
	var img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var placeholder = ImageTexture.create_from_image(img)
	cd_bar.texture_progress = placeholder

	layout.add_child(cd_bar)

	container.add_child(card)

func _on_unit_produced(unit):
	# Find index of unit
	var card_index = monitored_units.find(unit)
	if card_index == -1: return

	# Flash animation
	if card_index < container.get_child_count():
		var card = container.get_child(card_index)
		var style = card.get_theme_stylebox("panel").duplicate()
		card.add_theme_stylebox_override("panel", style)

		var tween = create_tween()
		tween.tween_property(style, "border_color", Color.WHITE, 0.1)
		tween.tween_property(style, "border_color", Color("#3498db"), 0.3)

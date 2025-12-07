extends Control

@onready var hp_bar = $Panel/VBoxContainer/HPBar
@onready var food_bar = $Panel/VBoxContainer/FoodBar
@onready var mana_bar = $Panel/VBoxContainer/ManaBar
@onready var wave_label = $Panel/WaveLabel

@onready var bench_container = $BenchContainer
@onready var sell_zone = $SellZone
@onready var skill_bar = $SkillBar

func _ready():
	GameManager.ui_manager = self
	GameManager.resource_changed.connect(update_ui)
	GameManager.wave_started.connect(update_ui)
	GameManager.wave_ended.connect(update_ui)
	update_ui()

func get_bench_slot_global_position(index: int) -> Vector2:
	if index < 0 or index >= bench_container.get_child_count():
		return Vector2.ZERO
	var slot = bench_container.get_child(index)
	# The slot center
	return slot.get_global_transform_with_canvas().origin + slot.size / 2.0

func is_point_in_sell_zone(global_point: Vector2) -> bool:
	return sell_zone.get_global_rect().has_point(global_point)

func is_point_in_bench(global_point: Vector2) -> int:
	for i in range(bench_container.get_child_count()):
		var slot = bench_container.get_child(i)
		if slot.get_global_rect().has_point(global_point):
			return i
	return -1

func _process(delta):
	update_skill_bar()

func update_skill_bar():
	# Scan for units with active skills
	# For efficiency, only do this if needed or every frame (game loop is simple enough)

	if !GameManager.grid_manager: return

	var active_units = []
	for key in GameManager.grid_manager.tiles:
		var tile = GameManager.grid_manager.tiles[key]
		if tile.unit and tile.unit.has_active_skill() and not (tile.unit in active_units):
			active_units.append(tile.unit)

	# Clear skill bar
	for child in skill_bar.get_children():
		child.queue_free()

	# Rebuild
	# Note: In a real game, we would optimize this to not delete/recreate every frame.
	# But given the task scope, let's try to be slightly smarter:
	# Only rebuild if count changes? Or just rebuild. Rebuilding buttons every frame kills interaction.
	# We MUST NOT rebuild every frame.

	# Let's check if the current children match the active units
	var current_buttons = skill_bar.get_children()
	if current_buttons.size() == active_units.size():
		var match_all = true
		for i in range(current_buttons.size()):
			var btn = current_buttons[i]
			if btn.get_meta("unit") != active_units[i]:
				match_all = false
				break
		if match_all:
			# Update cooldowns only
			for btn in current_buttons:
				_update_skill_button(btn)
			return

	# Rebuild
	for child in skill_bar.get_children():
		child.queue_free()

	for unit in active_units:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(60, 60)
		btn.text = unit.unit_data.skill.substr(0, 1) # First letter
		btn.set_meta("unit", unit)
		btn.pressed.connect(func(): unit.cast_skill())

		# Cooldown Overlay
		var cd_overlay = TextureProgressBar.new()
		cd_overlay.name = "CDOverlay"
		cd_overlay.fill_mode = TextureProgressBar.FILL_BOTTOM_TO_TOP
		cd_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		cd_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cd_overlay.visible = false
		cd_overlay.max_value = 10.0
		cd_overlay.step = 0.1
		cd_overlay.tint_progress = Color(0, 0, 0, 0.7)

		# Create a 1x1 white placeholder texture for progress
		var img = PlaceholderTexture2D.new()
		img.size = Vector2(1, 1)
		cd_overlay.texture_progress = img

		btn.add_child(cd_overlay)

		skill_bar.add_child(btn)
		_update_skill_button(btn)

func _update_skill_button(btn):
	var unit = btn.get_meta("unit")
	if !is_instance_valid(unit):
		btn.queue_free()
		return

	var cd_overlay = btn.get_node("CDOverlay")

	if unit.skill_cooldown > 0:
		btn.disabled = true
		cd_overlay.visible = true
		cd_overlay.value = unit.skill_cooldown
	else:
		btn.disabled = false
		cd_overlay.visible = false

func update_ui():
	hp_bar.value = (GameManager.core_health / GameManager.max_core_health) * 100
	food_bar.value = (GameManager.food / GameManager.max_food) * 100
	mana_bar.value = (GameManager.mana / GameManager.max_mana) * 100

	wave_label.text = "Wave %d" % GameManager.wave

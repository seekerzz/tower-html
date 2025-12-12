extends Control

signal sacrifice_requested

@onready var hp_bar = $Panel/VBoxContainer/HPBar
@onready var food_bar = $Panel/VBoxContainer/FoodBar
@onready var mana_bar = $Panel/VBoxContainer/ManaBar
@onready var enemy_bar = $Panel/VBoxContainer/EnemyProgressBar
@onready var hp_label = $Panel/VBoxContainer/HPBar/Label
@onready var food_label = $Panel/VBoxContainer/FoodBar/Label
@onready var mana_label = $Panel/VBoxContainer/ManaBar/Label
@onready var enemy_label = $Panel/VBoxContainer/EnemyProgressBar/Label
@onready var wave_label = $Panel/WaveLabel
@onready var debug_button = $Panel/DebugButton
@onready var skip_button = $Panel/SkipButton
@onready var wave_timeline = $WaveTimeline
@onready var stats_container = $DamageStats/ScrollContainer/VBoxContainer
@onready var damage_stats_panel = $DamageStats
@onready var stats_scroll = $DamageStats/ScrollContainer
@onready var stats_header = $DamageStats/Header

# New UI Elements for Rewards
var artifacts_hud: HBoxContainer

const FLOATING_TEXT_SCENE = preload("res://src/Scenes/UI/FloatingText.tscn")
const BUILD_PANEL_SCENE = preload("res://src/Scenes/UI/BuildPanel.tscn")
const TOOLTIP_SCENE = preload("res://src/Scenes/UI/Tooltip.tscn")

var damage_stats = {} # unit_id -> {name, icon, amount, node}
var last_sort_time: float = 0.0
var tooltip_instance = null
var sort_interval: float = 1.0
var is_stats_collapsed: bool = true
var stats_tween: Tween

func _ready():
	GameManager.resource_changed.connect(update_ui)
	GameManager.wave_started.connect(update_ui)
	GameManager.wave_ended.connect(update_ui)

	GameManager.damage_dealt.connect(_on_damage_dealt)
	GameManager.ftext_spawn_requested.connect(_on_ftext_spawn_requested)
	GameManager.wave_ended.connect(_on_wave_ended_stats)

	stats_header.gui_input.connect(_on_stats_header_input)

	_setup_ui_styles()

	if debug_button:
		debug_button.pressed.connect(_on_debug_button_pressed)
	if skip_button:
		skip_button.pressed.connect(_on_skip_button_pressed)
	_setup_tooltip()

	update_ui()
	update_timeline()
	_setup_build_panel()
	_setup_stats_panel()
	_setup_artifacts_hud()

func _setup_artifacts_hud():
	artifacts_hud = HBoxContainer.new()
	artifacts_hud.name = "ArtifactsHUD"
	# Position at top right
	add_child(artifacts_hud)
	artifacts_hud.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	artifacts_hud.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	artifacts_hud.alignment = BoxContainer.ALIGNMENT_END

	# With Top Right preset, the node is anchored to the top right.
	# We want to offset it slightly from the edge.
	# Since grow_horizontal is BEGIN, it expands to the left.
	# We set the position's x to be (ViewportWidth - Offset) or use offsets.
	# A safe way is to set the offsets directly after preset.
	artifacts_hud.offset_left = -320 # Starts 320px from right edge
	artifacts_hud.offset_right = -20 # Ends 20px from right edge
	artifacts_hud.offset_top = 20
	artifacts_hud.offset_bottom = 60 # 40px height

	# Connect to RewardManager if available
	var rm = GameManager.get("reward_manager")
	if not rm and GameManager.has_meta("reward_manager"):
		rm = GameManager.get_meta("reward_manager")

	if rm:
		rm.reward_added.connect(_on_reward_added)
		if rm.has_signal("sacrifice_state_changed"):
			rm.sacrifice_state_changed.connect(_on_sacrifice_state_changed)

func _on_reward_added(_id):
	_update_artifacts_hud()

func _on_sacrifice_state_changed(_is_active):
	# Update HUD to reflect cooldown/active state if needed
	_update_artifacts_hud()

func _update_artifacts_hud():
	if not artifacts_hud: return

	for child in artifacts_hud.get_children():
		child.queue_free()

	var rm = GameManager.get("reward_manager")
	if not rm and GameManager.has_meta("reward_manager"):
		rm = GameManager.get_meta("reward_manager")

	if not rm: return

	# 1. Process Active Buffs (Stats)
	for buff_id in rm.active_buffs:
		_create_hud_icon(buff_id, rm.active_buffs[buff_id], rm)

	# 2. Process Artifacts
	for artifact_id in rm.acquired_artifacts:
		_create_hud_icon(artifact_id, 1, rm)

func _create_hud_icon(id, count, rm):
	if not rm.REWARDS.has(id): return

	var data = rm.REWARDS[id]
	var icon_container = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.5)
	style.set_corner_radius_all(4)
	icon_container.add_theme_stylebox_override("panel", style)

	var label = Label.new()
	label.text = data.get("icon", "?")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(40, 40)
	label.add_theme_font_size_override("font_size", 24)
	label.tooltip_text = data.get("name", id) + "\n" + data.get("desc", "")

	icon_container.add_child(label)

	# Stack count
	if count > 1:
		var count_label = Label.new()
		count_label.text = "x%d" % count
		count_label.add_theme_font_size_override("font_size", 12)
		count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		# To make anchors work, parent needs to be control but Label inside container is managed.
		# Easier: just add it and move it or use a MarginContainer overlay.
		# Let's just add it as child of container, and set position manually or rely on order.
		# Or use a MarginContainer for the icon and overlay the count.
		# Simple approach: standard VBox/Overlay.
		# Since PanelContainer only holds one child usually, let's change structure slightly.

		# Better structure: MarginContainer
		var margin = MarginContainer.new()
		# Reparent label: remove from old parent first
		label.get_parent().remove_child(label)
		margin.add_child(label)

		var count_lbl_container = MarginContainer.new()
		count_lbl_container.add_theme_constant_override("margin_left", 20)
		count_lbl_container.add_theme_constant_override("margin_top", 20)
		count_lbl_container.add_child(count_label)

		margin.add_child(count_lbl_container)

		# Add margin to container
		icon_container.add_child(margin)

	# Interaction for Sacrifice Protocol
	if id == "sacrifice_protocol":
		icon_container.mouse_filter = Control.MOUSE_FILTER_STOP
		icon_container.gui_input.connect(_on_sacrifice_icon_input)

		# Visual feedback for cooldown
		if rm.sacrifice_cooldown > 0:
			label.modulate = Color(0.5, 0.5, 0.5, 0.5) # Greyed out
		elif rm.is_sacrifice_active:
			label.modulate = Color(1, 0, 0) # Red glow/active?
			# Or maybe scale pulse?

	artifacts_hud.add_child(icon_container)

func _on_sacrifice_icon_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var rm = GameManager.get("reward_manager")
		if not rm and GameManager.has_meta("reward_manager"):
			rm = GameManager.get_meta("reward_manager")

		if rm:
			rm.activate_sacrifice()

func _setup_ui_styles():
	var bg_color = Color(0.1, 0.1, 0.1, 0.8)
	var border_color = Color(0.0, 0.0, 0.0, 1.0)
	var radius = 6

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = bg_color
	bg_style.set_corner_radius_all(radius)
	bg_style.border_width_bottom = 2
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_color = border_color

	# HP Fill
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.8, 0.1, 0.1)
	hp_fill.set_corner_radius_all(radius)

	# Food Fill
	var food_fill = StyleBoxFlat.new()
	food_fill.bg_color = Color(1.0, 0.84, 0.0)
	food_fill.set_corner_radius_all(radius)

	# Mana Fill
	var mana_fill = StyleBoxFlat.new()
	mana_fill.bg_color = Color(0.2, 0.4, 1.0)
	mana_fill.set_corner_radius_all(radius)

	# Enemy Fill
	var enemy_fill = StyleBoxFlat.new()
	enemy_fill.bg_color = Color(0.6, 0.2, 0.8)
	enemy_fill.set_corner_radius_all(radius)

	if hp_bar:
		hp_bar.add_theme_stylebox_override("background", bg_style)
		hp_bar.add_theme_stylebox_override("fill", hp_fill)
	if food_bar:
		food_bar.add_theme_stylebox_override("background", bg_style)
		food_bar.add_theme_stylebox_override("fill", food_fill)
	if mana_bar:
		mana_bar.add_theme_stylebox_override("background", bg_style)
		mana_bar.add_theme_stylebox_override("fill", mana_fill)
	if enemy_bar:
		enemy_bar.add_theme_stylebox_override("background", bg_style)
		enemy_bar.add_theme_stylebox_override("fill", enemy_fill)

	var labels = [hp_label, food_label, mana_label, enemy_label]
	for label in labels:
		if label:
			label.add_theme_constant_override("outline_size", 4)
			label.add_theme_color_override("font_outline_color", Color.BLACK)

func _setup_stats_panel():
	# Anchor to Center Right
	damage_stats_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	# Initial state: Collapsed
	is_stats_collapsed = true
	# We need to defer position update because layout happens after ready
	call_deferred("_update_stats_panel_position")

func _update_stats_panel_position():
	_animate_stats_panel()

func _animate_stats_panel():
	if stats_tween and stats_tween.is_valid():
		stats_tween.kill()
	stats_tween = create_tween()

	# Ensure panel is on top
	damage_stats_panel.z_index = 10

	var viewport_width = get_viewport_rect().size.x
	var panel_width = damage_stats_panel.size.x

	var target_pos_x
	if is_stats_collapsed:
		stats_header.text = "📊"
		stats_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_scroll.visible = false
		damage_stats_panel.custom_minimum_size.y = 30 # Small height
		# Move mostly off-screen, leave 60px visible to ensure it's clickable
		target_pos_x = viewport_width - 60
	else:
		stats_header.text = "Damage Stats"
		stats_scroll.visible = true
		damage_stats_panel.custom_minimum_size.y = 300
		# Fully visible. Ensure panel width is at least something reasonable if dynamic
		target_pos_x = viewport_width - max(panel_width, 200)

	stats_tween.tween_property(damage_stats_panel, "position:x", target_pos_x, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _setup_build_panel():
	var build_panel = BUILD_PANEL_SCENE.instantiate()
	add_child(build_panel)
	# Position on the left side
	build_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	build_panel.position = Vector2(20, 100) # Offset from top
	# Ensure it stays on screen? Anchors should handle if set correctly, but manual pos for now.

func _setup_tooltip():
	tooltip_instance = TOOLTIP_SCENE.instantiate()
	add_child(tooltip_instance)
	tooltip_instance.hide()
	GameManager.show_tooltip.connect(_on_show_tooltip)
	GameManager.hide_tooltip.connect(_on_hide_tooltip)

func _on_show_tooltip(data, stats, buffs, pos):
	if tooltip_instance:
		tooltip_instance.show_tooltip(data, stats, buffs, pos)

func _on_hide_tooltip():
	if tooltip_instance:
		tooltip_instance.hide_tooltip()

func _process(delta):
	if last_sort_time > 0:
		last_sort_time -= delta

	_update_enemy_progress()

func _update_enemy_progress():
	if GameManager.is_wave_active and GameManager.combat_manager:
		var total = GameManager.combat_manager.total_enemies_for_wave
		var alive = get_tree().get_nodes_in_group("enemies").size()
		var to_spawn = GameManager.combat_manager.enemies_to_spawn
		var current_alive = alive + to_spawn

		# Progress: How many died? (Total - Current Alive) / Total
		# Or Remaining: Current Alive / Total
		# User requested: enemies_alive / total_wave_enemies

		if total > 0:
			enemy_bar.max_value = total
			enemy_bar.value = current_alive
			enemy_label.text = "%d / %d" % [current_alive, total]
		else:
			enemy_label.text = "0 / 0"
	else:
		enemy_label.text = "Waiting..."
		enemy_bar.value = 0

func _input(event):
	if event.is_action_pressed("ui_focus_next"): # Default F1 mapping often varies, but let's check scancode or specific action if defined
		pass
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		GameManager.activate_cheat()

func update_ui():
	var target_hp = (GameManager.core_health / GameManager.max_core_health) * 100
	create_tween().tween_property(hp_bar, "value", target_hp, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	food_bar.value = (GameManager.food / GameManager.max_food) * 100
	mana_bar.value = (GameManager.mana / GameManager.max_mana) * 100

	hp_label.text = "%d/%d" % [int(GameManager.core_health), int(GameManager.max_core_health)]
	food_label.text = "%d/%d (+%d/s)" % [int(GameManager.food), int(GameManager.max_food), int(GameManager.base_food_rate)]
	mana_label.text = "%d/%d (+%d/s)" % [int(GameManager.mana), int(GameManager.max_mana), int(GameManager.base_mana_rate)]

	wave_label.text = "Wave %d" % GameManager.wave
	update_timeline()

func update_timeline():
	for child in wave_timeline.get_children():
		child.queue_free()

	for i in range(10):
		var wave_idx = GameManager.wave + i
		var type_key = get_wave_type(wave_idx)

		var icon_label = Label.new()
		var icon_text = "?"
		var color = Color.WHITE

		if type_key == "boss":
			icon_text = "👹"
			color = Color.RED
		elif type_key == "event":
			icon_text = "🎁"
			color = Color.PURPLE
		elif Constants.ENEMY_VARIANTS.has(type_key):
			var variant = Constants.ENEMY_VARIANTS[type_key]
			icon_text = variant.get("icon", "?")
			color = variant.get("color", Color.WHITE)

		icon_label.text = icon_text
		icon_label.modulate = color
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		if i == 0:
			var panel = PanelContainer.new()
			panel.add_child(icon_label)
			wave_timeline.add_child(panel)
		else:
			wave_timeline.add_child(icon_label)

func get_wave_type(n: int) -> String:
	var types = ['slime', 'wolf', 'poison', 'treant', 'yeti', 'golem']
	if n % 10 == 0: return 'boss'
	if n % 3 == 0: return 'event'
	var idx = int(min(types.size() - 1, floor((n - 1) / 2.0)))
	return types[idx % types.size()]

func _on_damage_dealt(unit, amount):
	if not unit: return
	var id = unit.get_instance_id()

	if not damage_stats.has(id):
		# Create UI entry
		var row = HBoxContainer.new()
		var name_lbl = Label.new()
		var dmg_lbl = Label.new()

		var unit_name = "Unit"
		if "unit_data" in unit and unit.unit_data:
			unit_name = unit.unit_data.get("icon", "") + " " + unit.unit_data.get("name", "Unit")

		name_lbl.text = unit_name
		dmg_lbl.text = "0"
		dmg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		dmg_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		row.add_child(name_lbl)
		row.add_child(dmg_lbl)
		stats_container.add_child(row)

		damage_stats[id] = {
			"amount": 0,
			"dmg_lbl": dmg_lbl,
			"row": row
		}

	damage_stats[id].amount += amount
	damage_stats[id].dmg_lbl.text = str(int(damage_stats[id].amount))

	if last_sort_time <= 0:
		_sort_stats()
		last_sort_time = sort_interval

func _sort_stats():
	# Simple bubble sort or reordering of children based on amount
	var children = stats_container.get_children()
	children.sort_custom(func(a, b):
		var amt_a = _get_amount_from_row(a)
		var amt_b = _get_amount_from_row(b)
		return amt_a > amt_b
	)

	for i in range(children.size()):
		stats_container.move_child(children[i], i)

func _get_amount_from_row(row):
	for id in damage_stats:
		if damage_stats[id].row == row:
			return damage_stats[id].amount
	return 0

func _on_ftext_spawn_requested(pos, value, color):
	var ftext = FLOATING_TEXT_SCENE.instantiate()

	# Random Offset
	var offset = Vector2(randf_range(-20, 20), randf_range(-30, -10))
	var world_pos = pos + offset

	# Convert world position to canvas (UI) position if needed.
	var screen_pos = get_viewport().canvas_transform * world_pos

	ftext.position = screen_pos
	add_child(ftext)

	# Ensure value is integer formatted if it looks like a number
	var display_value = value
	if value.is_valid_float():
		display_value = str(int(float(value)))

	ftext.setup(display_value, color)

func _on_stats_header_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_stats_collapsed = !is_stats_collapsed
		_animate_stats_panel()

func _on_wave_ended_stats():
	# Reset stats on wave end? The ref implementation seems to reset on startWave.
	# Let's reset on wave start actually, but here we can clear if we want.
	# For now, let's keep them accumulative or reset on start_wave if we had that signal connected.
	# The ref code: game.damageStats = {}; in startWave.
	# So I should clear it in start_wave via update_ui logic or separate handler.
	pass

func _on_debug_button_pressed():
	GameManager.activate_cheat()

func _on_skip_button_pressed():
	if not GameManager.is_wave_active:
		return

	# Clear all enemies
	get_tree().call_group("enemies", "queue_free")

	# Stop spawning
	if GameManager.combat_manager:
		GameManager.combat_manager.enemies_to_spawn = 0

	# End wave
	GameManager.end_wave()

extends Control

signal sacrifice_requested

@onready var hp_bar = $TopLeftPanel/HPBar
@onready var food_bar = $TopLeftPanel/FoodBar
@onready var mana_bar = $TopLeftPanel/ManaBar
@onready var hp_label = $TopLeftPanel/HPBar/Label
@onready var food_label = $TopLeftPanel/FoodBar/Label
@onready var mana_label = $TopLeftPanel/ManaBar/Label
@onready var wave_label = $Panel/WaveLabel
@onready var debug_button = $DebugButton
@onready var skip_button = $SkipButton
@onready var stats_container = $DamageStats/ScrollContainer/VBoxContainer
@onready var damage_stats_panel = $DamageStats
@onready var stats_scroll = $DamageStats/ScrollContainer
@onready var stats_header = $DamageStats/Header
@onready var stats_toggle_btn = $DamageStats/ToggleButton
@onready var left_sidebar = $LeftSidebar
@onready var cutin_manager = $CutInManager

@onready var game_over_panel = $GameOverPanel
@onready var retry_button = $GameOverPanel/RetryWaveButton
@onready var new_game_button = $GameOverPanel/NewGameButton

# Artifacts logic moved to ArtifactsPanel.gd, which is instanced in Scene.

const FLOATING_TEXT_SCENE = preload("res://src/Scenes/UI/FloatingText.tscn")
const TOOLTIP_SCENE = preload("res://src/Scenes/UI/Tooltip.tscn")

var damage_stats = {} # unit_id -> {name, icon, amount, node}
var last_sort_time: float = 0.0
var tooltip_instance = null
var sort_interval: float = 1.0
var is_stats_collapsed: bool = true
var stats_tween: Tween
var sidebar_tween: Tween

func _ready():
	GameManager.resource_changed.connect(update_ui)
	GameManager.wave_started.connect(update_ui)
	GameManager.wave_ended.connect(update_ui)

	GameManager.wave_started.connect(_update_hud_visibility)
	GameManager.wave_started.connect(_force_collapse_stats) # Added for requirement
	GameManager.wave_ended.connect(_update_hud_visibility)

	# Connect for sidebar movement
	GameManager.wave_started.connect(_update_sidebar_position)
	GameManager.wave_ended.connect(_update_sidebar_position)

	# Connect to wave ended for stats auto-popup as requested
	GameManager.wave_ended.connect(_on_wave_ended_stats)

	GameManager.game_over.connect(_on_game_over)

	GameManager.damage_dealt.connect(_on_damage_dealt)
	GameManager.skill_activated.connect(_on_skill_activated)
	GameManager.ftext_spawn_requested.connect(_on_ftext_spawn_requested)

	stats_toggle_btn.pressed.connect(_on_stats_toggle_pressed)

	_setup_ui_styles()

	if debug_button:
		debug_button.pressed.connect(_on_debug_button_pressed)
	if skip_button:
		skip_button.pressed.connect(_on_skip_button_pressed)

	if retry_button:
		retry_button.pressed.connect(_on_retry_wave_pressed)
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)

	_setup_tooltip()

	update_ui()
	_setup_stats_panel()

	# Initial visibility state
	_update_hud_visibility()
	_update_sidebar_position()

func _update_hud_visibility():
	var active = GameManager.is_wave_active
	hp_bar.visible = active
	food_bar.visible = active
	mana_bar.visible = active

func _update_sidebar_position():
	if sidebar_tween and sidebar_tween.is_valid():
		sidebar_tween.kill()
	sidebar_tween = create_tween()

	var target_offset_bottom = -10 # Default for combat
	if not GameManager.is_wave_active:
		# Shop is open, occupy bottom 200px
		target_offset_bottom = -210

	# Animate LeftSidebar
	# We are animating offset_bottom.
	# Note: LeftSidebar is anchored Bottom Left with Vertical Grow Up.
	# So changing offset_bottom moves the whole container up/down relative to bottom anchor.
	sidebar_tween.tween_property(left_sidebar, "offset_bottom", float(target_offset_bottom), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _setup_ui_styles():
	var radius = 6

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

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	bg_style.set_corner_radius_all(radius)

	if hp_bar:
		hp_bar.add_theme_stylebox_override("background", bg_style)
		hp_bar.add_theme_stylebox_override("fill", hp_fill)
	if food_bar:
		food_bar.add_theme_stylebox_override("background", bg_style)
		food_bar.add_theme_stylebox_override("fill", food_fill)
	if mana_bar:
		mana_bar.add_theme_stylebox_override("background", bg_style)
		mana_bar.add_theme_stylebox_override("fill", mana_fill)

	var labels = [hp_label, food_label, mana_label]
	for label in labels:
		if label:
			label.add_theme_constant_override("outline_size", 4)
			label.add_theme_color_override("font_outline_color", Color.BLACK)
			label.add_theme_font_size_override("font_size", 18) # Larger font

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
		stats_scroll.visible = false
		damage_stats_panel.custom_minimum_size.y = 30
		target_pos_x = viewport_width
	else:
		stats_scroll.visible = true
		damage_stats_panel.custom_minimum_size.y = 300
		target_pos_x = viewport_width - max(panel_width, 200)

	stats_tween.tween_property(damage_stats_panel, "position:x", target_pos_x, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

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

	_update_cutin_position()

func _update_cutin_position():
	if not cutin_manager or not left_sidebar: return

	# Determine top of the active skill UI (SkillBar)
	# LeftSidebar contains SkillBar at the top? No, it's VBox.
	# children: SkillBar, EnemyProgressBar.
	# If aligned to bottom (default for VBox unless specific anchors?), items are stacked.
	# LeftSidebar is anchored Bottom Left.

	# We want CutInManager to be just above the SkillBar.
	# Since CutInManager stacks UP, its position should be the bottom-most point where new cutins appear.
	# This point should be the Top of the SkillBar.

	var skill_bar = left_sidebar.get_node_or_null("SkillBar")
	if skill_bar and skill_bar.visible:
		# Calculate global Y of SkillBar top
		var sb_global_y = skill_bar.global_position.y

		var item_height = 120.0
		if cutin_manager and "ITEM_HEIGHT" in cutin_manager:
			item_height = cutin_manager.ITEM_HEIGHT

		# Set CutInManager position
		# Assuming CutInManager is child of MainGUI (Control)
		# We want local position relative to MainGUI
		# We offset Y by -ITEM_HEIGHT because items are drawn downwards from (0,0) and we want them above the bar.
		# The Manager acts as the anchor point for the bottom-most (newest) item's TOP edge?
		# No, CutInManager spawns item at (0,0). Item height is ITEM_HEIGHT.
		# So item occupies (0,0) to (width, ITEM_HEIGHT).
		# If we want the BOTTOM of the item to be at sb_global_y, we need to place Manager at sb_global_y - ITEM_HEIGHT.

		var local_pos = get_global_transform().affine_inverse() * Vector2(left_sidebar.global_position.x, sb_global_y - item_height)

		cutin_manager.position = local_pos
		# Ensure correct X (aligned with sidebar)
		cutin_manager.position.x = left_sidebar.position.x

		# Calculate available height for stacking
		# Ceiling is the bottom of TopLeftPanel
		var top_left_panel = $TopLeftPanel
		if top_left_panel:
			var panel_bottom = top_left_panel.global_position.y + top_left_panel.size.y
			# The CutInManager is positioned at sb_global_y - item_height (which is the top of the NEWEST item)
			# The stack grows UPWARDS from there.
			# So we check space between CutInManager position and Panel bottom.
			# However, we should consider that items are placed at negative Y relative to CutInManager.
			# So valid Y range for items is [-available, 0].
			# Effectively, available_height = (sb_global_y - item_height) - panel_bottom

			var space = (sb_global_y - item_height) - panel_bottom
			cutin_manager.available_height = max(0.0, space)

func _input(event):
	if event.is_action_pressed("ui_focus_next"):
		pass
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		GameManager.activate_cheat()

func update_ui():
	_update_hud_visibility()

	var target_hp = (GameManager.core_health / GameManager.max_core_health) * 100
	create_tween().tween_property(hp_bar, "value", target_hp, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	food_bar.value = (GameManager.food / GameManager.max_food) * 100
	mana_bar.value = (GameManager.mana / GameManager.max_mana) * 100

	# Updated labels with Emojis as requested
	hp_label.text = "❤️ %d/%d" % [int(GameManager.core_health), int(GameManager.max_core_health)]
	food_label.text = "🌽 %d/%d" % [int(GameManager.food), int(GameManager.max_food)]
	mana_label.text = "💧 %d/%d" % [int(GameManager.mana), int(GameManager.max_mana)]

	wave_label.text = "Wave %d" % GameManager.wave

func _on_skill_activated(unit):
	if cutin_manager:
		# Construct a rich data object including type_key for icon lookup
		var data = unit.unit_data.duplicate()
		data["type_key"] = unit.type_key
		cutin_manager.trigger_cutin(data)

func _on_damage_dealt(unit, amount):
	if not unit: return
	var id = unit.get_instance_id()

	if not damage_stats.has(id):
		# Create UI entry
		var row = HBoxContainer.new()

		# Icon
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(24, 24)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		if "type_key" in unit:
			var icon = AssetLoader.get_unit_icon(unit.type_key)
			if icon:
				icon_rect.texture = icon

		row.add_child(icon_rect)

		var name_lbl = Label.new()
		var dmg_lbl = Label.new()

		var unit_name = "Unit"
		if "unit_data" in unit and unit.unit_data:
			unit_name = unit.unit_data.get("name", "Unit")

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

func _on_stats_toggle_pressed():
	is_stats_collapsed = !is_stats_collapsed
	_animate_stats_panel()

func _force_collapse_stats():
	if !is_stats_collapsed:
		is_stats_collapsed = true
		_animate_stats_panel()

func _on_wave_ended_stats():
	# Auto pop up stats
	if is_stats_collapsed:
		is_stats_collapsed = false
		_animate_stats_panel()

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

func _on_game_over():
	if game_over_panel:
		game_over_panel.show()

func _on_retry_wave_pressed():
	if game_over_panel:
		game_over_panel.hide()
	GameManager.retry_wave()

func _on_new_game_pressed():
	get_tree().reload_current_scene()

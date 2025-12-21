extends Control

signal sacrifice_requested

@onready var hp_bar = $TopLeftPanel/HPBar
@onready var food_bar = $TopLeftPanel/FoodBar
@onready var mana_bar = $TopLeftPanel/ManaBar
@onready var hp_label = $TopLeftPanel/HPBar/Label
@onready var food_label = $TopLeftPanel/FoodBar/Label
@onready var mana_label = $TopLeftPanel/ManaBar/Label
@onready var wave_label = $Panel/WaveLabel
@onready var stats_container = $DamageStats/ScrollContainer/VBoxContainer
@onready var damage_stats_panel = $DamageStats
@onready var stats_scroll = $DamageStats/ScrollContainer
@onready var stats_header = $DamageStats/Header
# Removed stats_toggle_btn as per refactor
@onready var left_sidebar = $LeftSidebar
@onready var right_sidebar = $RightSidebar
@onready var top_left_panel = $TopLeftPanel

@onready var game_over_panel = $GameOverPanel
@onready var retry_button = $GameOverPanel/RetryWaveButton
@onready var new_game_button = $GameOverPanel/NewGameButton
@onready var cutin_manager = $CutInManager

# Artifacts logic moved to ArtifactsPanel.gd, which is instanced in Scene.

const FLOATING_TEXT_SCENE = preload("res://src/Scenes/UI/FloatingText.tscn")
const TOOLTIP_SCENE = preload("res://src/Scenes/UI/Tooltip.tscn")

var damage_stats = {} # unit_id -> {name, icon, amount, node}
var last_sort_time: float = 0.0
var tooltip_instance = null
var sort_interval: float = 1.0
var sidebar_tween: Tween
var shop_node: Control = null

# New Combat Gold Label
var combat_gold_label: Label

func _ready():
	GameManager.resource_changed.connect(update_ui)
	GameManager.wave_started.connect(update_ui)
	GameManager.wave_ended.connect(update_ui)

	GameManager.wave_started.connect(_update_hud_visibility)
	GameManager.wave_ended.connect(_update_hud_visibility)

	# Connect for sidebar movement
	GameManager.wave_started.connect(_update_sidebar_position)
	GameManager.wave_ended.connect(_update_sidebar_position)

	GameManager.game_over.connect(_on_game_over)

	GameManager.damage_dealt.connect(_on_damage_dealt)
	GameManager.skill_activated.connect(_on_skill_activated)
	GameManager.ftext_spawn_requested.connect(_on_ftext_spawn_requested)

	_setup_ui_styles()

	if retry_button:
		retry_button.pressed.connect(_on_retry_wave_pressed)
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)

	_setup_tooltip()

	_setup_stats_panel()
	_setup_combat_gold_label()
	_setup_right_sidebar_layout()

	# Try to find Shop node dynamically
	shop_node = get_tree().root.find_child("Shop", true, false)
	if not shop_node and GameManager.get("main_game"):
		# If MainGame reference exists, try there
		shop_node = GameManager.main_game.find_child("Shop", true, false)

	if shop_node and shop_node.has_signal("shop_state_changed"):
		if not shop_node.shop_state_changed.is_connected(_update_sidebar_position_from_signal):
			shop_node.shop_state_changed.connect(_update_sidebar_position_from_signal)

	update_ui()

	# Initial visibility state
	_update_hud_visibility()
	_update_sidebar_position()

func _setup_combat_gold_label():
	combat_gold_label = Label.new()
	combat_gold_label.name = "CombatGoldLabel"
	# Icon + Text
	combat_gold_label.text = "💰 0"
	combat_gold_label.add_theme_font_size_override("font_size", 20)
	combat_gold_label.add_theme_color_override("font_outline_color", Color.BLACK)
	combat_gold_label.add_theme_constant_override("outline_size", 4)

	# Position below TopLeftPanel
	# Assuming TopLeftPanel is a container or control at top left.
	# We can add it as a child of TopLeftPanel if it's a VBox, or as a sibling.
	# To be safe and flexible, we add it to MainGUI and position it relative to TopLeftPanel.
	# However, simplest is adding to TopLeftPanel if it handles layout.
	# If TopLeftPanel is just a Panel, we can anchor the label.

	top_left_panel.add_child(combat_gold_label)
	# Assuming TopLeftPanel is a VBoxContainer or similar vertical layout.
	# If not, we might need to position it manually.
	# Given the structure (HPBar, FoodBar etc inside), it's likely a VBoxContainer.
	# If it's a Panel, we might need to check.
	# Let's assume VBoxContainer for now as it contains bars.
	# If it's a normal Panel, the bars are likely positioned manually or with anchors.
	# Let's check TopLeftPanel type if possible? No.
	# We'll set it to be at the bottom of the TopLeftPanel if it's not a container.
	if not top_left_panel is Container:
		combat_gold_label.layout_mode = 1
		combat_gold_label.anchors_preset = Control.PRESET_BOTTOM_LEFT
		combat_gold_label.position.y = top_left_panel.size.y + 10

func _setup_right_sidebar_layout():
	if not right_sidebar: return

	# Update right_sidebar anchors to fill vertical space
	right_sidebar.anchor_top = 0
	right_sidebar.anchor_bottom = 1
	# We assume anchors for left/right are handled in scene or elsewhere,
	# but ensure it stretches vertically.

	# Create Unified Container
	var right_content = VBoxContainer.new()
	right_content.name = "RightContentBox"
	right_content.layout_mode = 1
	right_content.anchors_preset = Control.PRESET_FULL_RECT
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_content.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Use separation constant instead of Spacer
	right_content.add_theme_constant_override("separation", 10)

	# Pack content at bottom so new rows grow upwards (conceptually)
	right_content.alignment = BoxContainer.ALIGNMENT_END

	right_sidebar.add_child(right_content)

	# Find PassiveSkillBar and InventoryPanel
	var passive_bar = right_sidebar.get_node_or_null("PassiveSkillBar")
	if not passive_bar:
		passive_bar = get_node_or_null("PassiveSkillBar")
	if not passive_bar:
		passive_bar = find_child("PassiveSkillBar", true, false)

	var inv_panel = right_sidebar.get_node_or_null("InventoryPanel")
	if not inv_panel:
		inv_panel = get_node_or_null("InventoryPanel")
	if not inv_panel:
		inv_panel = find_child("InventoryPanel", true, false)

	if passive_bar:
		if passive_bar.get_parent() != right_content:
			passive_bar.reparent(right_content)
		passive_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Don't expand vertical, let it take min size so it packs at bottom
		# But we want width consistence, so ensure expand fill
		passive_bar.size_flags_vertical = Control.SIZE_SHRINK_END

		# Ensure order: Passive Top
		right_content.move_child(passive_bar, 0)

	if inv_panel:
		if inv_panel.get_parent() != right_content:
			inv_panel.reparent(right_content)
		inv_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inv_panel.size_flags_vertical = Control.SIZE_SHRINK_END
		# Ensure order: Inventory Bottom
		# If passive is there, this is index 1
		right_content.move_child(inv_panel, right_content.get_child_count() - 1)

func _setup_stats_panel():
	# Requirements:
	# 1. Position: Left side (handled by logic/layout, but assumed currently Center Right?)
	# The prompt says "Ensure DamageStats panel is located on screen left".
	# Current code: damage_stats_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	# We change this to LEFT.
	damage_stats_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	damage_stats_panel.position.x = 0 # Stick to left

	# 2. Click through
	damage_stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if stats_scroll:
		stats_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if stats_container:
		stats_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 3. Visibility logic is handled in _update_hud_visibility

func _update_hud_visibility():
	var is_combat = GameManager.is_wave_active

	hp_bar.visible = is_combat
	food_bar.visible = is_combat
	mana_bar.visible = is_combat

	# Damage Stats: Hidden in Combat, Visible in Shop
	# "Combat (Combat): auto hide (visible = false)"
	# "Shop/Preparation (Shop): auto show (visible = true)"
	if damage_stats_panel:
		damage_stats_panel.visible = !is_combat

	# Combat Gold Label: Visible in Combat, Hidden in Shop
	if combat_gold_label:
		combat_gold_label.visible = is_combat

func _update_sidebar_position_from_signal(is_expanded):
	_update_sidebar_position()

func _update_sidebar_position():
	if sidebar_tween and sidebar_tween.is_valid():
		sidebar_tween.kill()
	sidebar_tween = create_tween()

	var target_offset_bottom = -10 # Default for combat
	var shop_height = 0.0

	# Check shop state logic
	if shop_node and is_instance_valid(shop_node) and shop_node.has_method("get_shop_height"):
		shop_height = shop_node.get_shop_height()
	elif not GameManager.is_wave_active:
		# Fallback if method missing but presumably shop phase
		shop_height = 300.0

	if shop_height > 0:
		target_offset_bottom = -(shop_height + 20) # 20 padding

	sidebar_tween.set_parallel(true)
	sidebar_tween.tween_property(left_sidebar, "offset_bottom", float(target_offset_bottom), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if right_sidebar:
		sidebar_tween.tween_property(right_sidebar, "offset_bottom", float(target_offset_bottom), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

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
			label.add_theme_font_size_override("font_size", 18)

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

	_update_cutin_layout()

func _update_cutin_layout():
	if !cutin_manager or !top_left_panel or !left_sidebar: return

	var top_panel_bottom = top_left_panel.position.y + top_left_panel.size.y
	var left_sidebar_top = left_sidebar.position.y

	var x_pos = top_left_panel.position.x
	var width = 270.0

	var available_height = left_sidebar_top - top_panel_bottom

	var new_rect = Rect2(x_pos, top_panel_bottom, width, available_height)
	cutin_manager.update_area(new_rect)

func _input(event):
	pass

func update_ui():
	# _update_hud_visibility() # Removed to prevent overriding the phase logic every update

	var target_hp = (GameManager.core_health / GameManager.max_core_health) * 100
	create_tween().tween_property(hp_bar, "value", target_hp, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	food_bar.value = (GameManager.food / GameManager.max_food) * 100
	mana_bar.value = (GameManager.mana / GameManager.max_mana) * 100

	hp_label.text = "❤️ %d/%d" % [int(GameManager.core_health), int(GameManager.max_core_health)]
	food_label.text = "🌽 %d/%d" % [int(GameManager.food), int(GameManager.max_food)]
	mana_label.text = "💧 %d/%d" % [int(GameManager.mana), int(GameManager.max_mana)]

	wave_label.text = "Wave %d" % GameManager.wave

	if combat_gold_label:
		combat_gold_label.text = "💰 %d" % GameManager.gold

func _on_damage_dealt(unit, amount):
	if not unit: return
	var id = unit.get_instance_id()

	if not damage_stats.has(id):
		var row = HBoxContainer.new()
		# Make row ignore mouse
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(24, 24)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignore mouse

		if "type_key" in unit:
			var icon = AssetLoader.get_unit_icon(unit.type_key)
			if icon:
				icon_rect.texture = icon

		row.add_child(icon_rect)

		var name_lbl = Label.new()
		var dmg_lbl = Label.new()

		# Ignore mouse on labels
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dmg_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

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

func _on_skill_activated(unit):
	if cutin_manager:
		cutin_manager.trigger_cutin(unit)

func _on_ftext_spawn_requested(pos, value, color):
	var ftext = FLOATING_TEXT_SCENE.instantiate()
	var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	var world_pos = pos + offset
	var screen_pos = get_viewport().canvas_transform * world_pos

	ftext.position = screen_pos
	add_child(ftext)

	var value_num: float = 0.0
	var display_value = str(value)

	if display_value.is_valid_float():
		value_num = float(display_value)
		display_value = str(int(value_num))

	var is_crit = color.r > 0.9 and color.g > 0.8 and color.b < 0.4

	ftext.setup(display_value, color, is_crit, value_num)

func _on_game_over():
	if game_over_panel:
		game_over_panel.show()

func _on_retry_wave_pressed():
	if game_over_panel:
		game_over_panel.hide()
	GameManager.retry_wave()

func _on_new_game_pressed():
	get_tree().reload_current_scene()

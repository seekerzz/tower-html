extends Control

# Shop Logic
var shop_items: Array = []
var shop_locked: Array = [false, false, false, false]
const SHOP_SIZE = 4

# Node References
@onready var shop_container = $Panel/MainContainer/Zone2/ShopContainer
@onready var refresh_btn = $Panel/MainContainer/Zone1/FunctionButtons/RefreshButton
@onready var expand_btn = $Panel/MainContainer/Zone1/FunctionButtons/ExpandButton
@onready var start_wave_btn = $Panel/MainContainer/Zone1/FunctionButtons/StartWaveButton
@onready var sell_zone_container = $Panel/MainContainer/Zone1/SellZoneContainer
@onready var global_preview = $Panel/MainContainer/Zone3/GlobalPreview
@onready var current_details = $Panel/MainContainer/Zone3/CurrentDetails
@onready var gold_label = $Panel/MainContainer/Zone2/GoldLabel
@onready var toggle_handle = $Panel/ToggleHandle

var sell_zone = null
var is_collapsed: bool = false
var panel_initial_y: float = 0.0

signal unit_bought(unit_key)

func _ready():
	GameManager.resource_changed.connect(update_ui)
	GameManager.wave_started.connect(on_wave_started)
	GameManager.wave_ended.connect(on_wave_ended)
	if GameManager.has_signal("wave_reset"):
		GameManager.wave_reset.connect(on_wave_reset)

	refresh_shop(true)
	update_ui()
	update_wave_info()

	expand_btn.pressed.connect(_on_expand_button_pressed)

	_create_sell_zone()
	call_deferred("_setup_collapse_handle")

	# Apply styles
	_apply_styles()

func _setup_collapse_handle():
	panel_initial_y = $Panel.position.y

	# ToggleHandle is now in Tscn, just connect signal
	if toggle_handle:
		if not toggle_handle.pressed.is_connected(_on_toggle_handle_pressed):
			toggle_handle.pressed.connect(_on_toggle_handle_pressed)

func _on_toggle_handle_pressed():
	if is_collapsed:
		expand_shop()
	else:
		collapse_shop()

func collapse_shop():
	if is_collapsed: return
	is_collapsed = true
	if toggle_handle: toggle_handle.text = "▲"

	var tween = create_tween()
	# Move panel down so only handle is visible at bottom
	var target_y = panel_initial_y + $Panel.size.y
	tween.tween_property($Panel, "position:y", target_y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func expand_shop():
	if !is_collapsed: return
	is_collapsed = false
	if toggle_handle: toggle_handle.text = "▼"

	var tween = create_tween()
	tween.tween_property($Panel, "position:y", panel_initial_y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _apply_styles():
	# Style Panel
	var panel = $Panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.border_width_top = 2
	panel_style.border_color = Color("#ffffff")
	panel.add_theme_stylebox_override("panel", panel_style)

	# Style Buttons
	apply_button_style(refresh_btn, Color("#3498db")) # Blue
	apply_button_style(expand_btn, Color("#2ecc71")) # Green
	apply_button_style(start_wave_btn, Color("#e74c3c"), true) # Red, Main Action

func apply_button_style(button: Button, color: Color, is_main_action: bool = false):
	var corner_radius = 8

	# Normal State
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = color
	style_normal.set_corner_radius_all(corner_radius)

	# Hover State
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = color.lightened(0.2)

	# Pressed State
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = color.darkened(0.2)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)

	button.add_theme_font_size_override("font_size", 24) # Emoji size

func _create_sell_zone():
	# Create a visual area for selling inside Zone 1 -> SellZoneContainer
	sell_zone = PanelContainer.new()
	sell_zone.set_script(load("res://src/Scripts/UI/SellZone.gd"))
	var lbl = Label.new()
	lbl.text = "💰\nSELL"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sell_zone.add_child(lbl)

	# Add to SellZoneContainer
	sell_zone_container.add_child(sell_zone)
	sell_zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Make sure it fills
	sell_zone.size_flags_horizontal = SIZE_EXPAND_FILL
	sell_zone.size_flags_vertical = SIZE_EXPAND_FILL

	sell_zone.mouse_filter = MOUSE_FILTER_STOP

	# Style Sell Zone
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 0.3, 0.3, 0.3)
	style.set_corner_radius_all(12)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 0, 0, 0.5)

	sell_zone.add_theme_stylebox_override("panel", style)

func update_ui():
	if gold_label:
		gold_label.text = "💰 %d" % GameManager.gold
	update_wave_info()

func update_wave_info():
	if !global_preview: return

	# Clear previous
	for child in global_preview.get_children():
		child.queue_free()

	# Global Preview (Timeline) - Next 5 waves
	for i in range(5):
		var wave_idx = GameManager.wave + i
		var type_key = get_wave_type(wave_idx)

		var icon = Label.new()
		icon.text = get_wave_icon(type_key)
		icon.tooltip_text = "Wave %d: %s" % [wave_idx, type_key.capitalize()]

		if i == 0:
			icon.modulate = Color(1, 1, 0) # Highlight current
			icon.add_theme_font_size_override("font_size", 20)
		else:
			icon.modulate = Color(1, 1, 1, 0.7)

		global_preview.add_child(icon)

	# Current Details
	if current_details:
		var type = get_wave_type(GameManager.wave)
		var total_enemies = 20 + floor(GameManager.wave * 6)
		var enemy_name = type.capitalize()
		var icon = get_wave_icon(type)
		current_details.text = "%s %s\nx%d" % [icon, enemy_name, total_enemies]

func get_wave_type(n: int) -> String:
	var types = ['slime', 'wolf', 'poison', 'treant', 'yeti', 'golem']
	if n % 10 == 0: return 'boss'
	if n % 3 == 0: return 'event'
	var idx = int(min(types.size() - 1, floor((n - 1) / 2.0)))
	return types[idx % types.size()]

func get_wave_icon(type_key: String) -> String:
	if type_key == "boss": return "👹"
	if type_key == "event": return "🎁"
	if Constants.ENEMY_VARIANTS.has(type_key):
		return Constants.ENEMY_VARIANTS[type_key].get("icon", "?")
	return "?"

func refresh_shop(force: bool = false):
	if !force and GameManager.gold < 10: return
	if !force:
		GameManager.spend_gold(10)

	var keys = Constants.UNIT_TYPES.keys()
	var new_items = []

	for i in range(SHOP_SIZE):
		if !force and shop_items.size() > i and shop_locked[i]:
			new_items.append(shop_items[i])
		else:
			new_items.append(keys.pick_random())

	shop_items = new_items

	for child in shop_container.get_children():
		child.queue_free()

	for i in range(SHOP_SIZE):
		create_shop_card(i, shop_items[i])

func create_shop_card(index, unit_key):
	var card = ShopCard.new()
	card.setup(unit_key)
	card.custom_minimum_size = Vector2(80, 100)
	card.size_flags_horizontal = SIZE_EXPAND_FILL

	card.card_clicked.connect(func(key): buy_unit(index, key, card))

	card.mouse_entered.connect(func():
		var proto = Constants.UNIT_TYPES[unit_key]
		var stats = {
			"damage": proto.damage,
			"range": proto.range,
			"atk_speed": proto.get("atkSpeed", proto.get("atk_speed", 1.0))
		}
		GameManager.show_tooltip.emit(proto, stats, [], card.get_global_mouse_position())
	)
	card.mouse_exited.connect(func(): GameManager.hide_tooltip.emit())

	shop_container.add_child(card)

func buy_unit(index, unit_key, card_ref):
	if GameManager.is_wave_active: return
	var proto = Constants.UNIT_TYPES[unit_key]
	if GameManager.gold >= proto.cost:
		if GameManager.main_game and GameManager.main_game.add_to_bench(unit_key):
			GameManager.spend_gold(proto.cost)
			unit_bought.emit(unit_key)
			card_ref.modulate = Color(0.5, 0.5, 0.5)
			card_ref.mouse_filter = MOUSE_FILTER_IGNORE
		else:
			print("Bench Full")
	else:
		print("Not enough gold")

func on_wave_started():
	refresh_btn.disabled = true
	expand_btn.disabled = true
	start_wave_btn.disabled = true
	start_wave_btn.text = "⚔️"
	collapse_shop()

func on_wave_ended():
	refresh_btn.disabled = false
	expand_btn.disabled = false
	start_wave_btn.disabled = false
	refresh_shop(true)
	expand_shop()

func on_wave_reset():
	refresh_btn.disabled = false
	expand_btn.disabled = false
	start_wave_btn.disabled = false

func _on_start_wave_button_pressed():
	GameManager.start_wave()

func _on_refresh_button_pressed():
	refresh_shop(false)

func _on_expand_button_pressed():
	if GameManager.grid_manager:
		GameManager.grid_manager.toggle_expansion_mode()

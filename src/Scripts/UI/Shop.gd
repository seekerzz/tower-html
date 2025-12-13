extends Control

# Shop Logic
var shop_items: Array = []
var shop_locked: Array = [false, false, false, false]
const SHOP_SIZE = 4

@onready var shop_container = $Panel/HBoxContainer
@onready var gold_label = $Panel/GoldLabel
@onready var refresh_btn = $Panel/RefreshButton
@onready var expand_btn = $Panel/ExpandButton
@onready var start_wave_btn = $Panel/StartWaveButton

var sell_zone = null

signal unit_bought(unit_key)

func _ready():
	GameManager.resource_changed.connect(update_ui)
	GameManager.wave_started.connect(on_wave_started)
	GameManager.wave_ended.connect(on_wave_ended)
	if GameManager.has_signal("wave_reset"):
		GameManager.wave_reset.connect(on_wave_reset)
	refresh_shop(true)
	update_ui()

	expand_btn.pressed.connect(_on_expand_button_pressed)

	_create_sell_zone()

	# Style Panel
	var panel = $Panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	panel_style.border_width_top = 2
	panel_style.border_color = Color("#ffffff")
	panel.add_theme_stylebox_override("panel", panel_style)

	# Style Buttons
	apply_button_style(refresh_btn, Color("#3498db")) # Blue
	apply_button_style(expand_btn, Color("#2ecc71")) # Green
	apply_button_style(start_wave_btn, Color("#e74c3c"), true) # Red, Main Action

func apply_button_style(button: Button, color: Color, is_main_action: bool = false):
	var corner_radius = 12 if is_main_action else 10

	# Normal State
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = color
	style_normal.set_corner_radius_all(corner_radius)

	# Hover State (Brighter)
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = color.lightened(0.2)

	# Pressed State (Darker)
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = color.darkened(0.2)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)

	if is_main_action:
		# Make it bold/larger. Since we can't easily switch font to bold without resource,
		# we assume default font or use scale/size.
		# Increasing font size override.
		button.add_theme_font_size_override("font_size", 20)
		# Add outline to make it pop
		button.add_theme_constant_override("outline_size", 2)
		button.add_theme_color_override("font_outline_color", Color.BLACK)

func _create_sell_zone():
	# Create a visual area for selling
	sell_zone = PanelContainer.new()
	sell_zone.set_script(load("res://src/Scripts/UI/SellZone.gd"))
	var lbl = Label.new()
	lbl.text = "💰\nSELL"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sell_zone.add_child(lbl)

	# Place it to the right of bench or somewhere prominent
	$Panel.add_child(sell_zone)
	sell_zone.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	sell_zone.position = Vector2($Panel.size.x - 100, 20)
	sell_zone.custom_minimum_size = Vector2(80, 80)
	# Remove modulate as we are using StyleBox
	# sell_zone.modulate = Color(1, 0.5, 0.5)
	sell_zone.mouse_filter = MOUSE_FILTER_STOP

	# Style Sell Zone
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 0.3, 0.3, 0.3)
	style.set_corner_radius_all(40) # Circular for 80x80
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 0, 0, 0.5)

	sell_zone.add_theme_stylebox_override("panel", style)

func update_ui():
	gold_label.text = "💰 %d" % GameManager.gold

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
	card.custom_minimum_size = Vector2(100, 120)

	card.card_clicked.connect(func(key): buy_unit(index, key, card))

	# Connect Tooltip signals (ShopCard handles its own mouse_entered/exited for visuals,
	# but we can also connect for tooltip here or let ShopCard handle it?
	# ShopCard sets tooltip_text, which is standard Godot tooltip.
	# But existing code uses GameManager.show_tooltip custom signal.
	# I should preserve that behavior.)

	card.mouse_entered.connect(func():
		var proto = Constants.UNIT_TYPES[unit_key]
		var stats = {
			"damage": proto.damage,
			"range": proto.range,
			"atk_speed": proto.get("atkSpeed", proto.get("atk_speed", 1.0))
		}
		# Need global position. ShopCard is a Control.
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
			# Disable card (visual indication?)
			card_ref.modulate = Color(0.5, 0.5, 0.5) # Dim it
			card_ref.mouse_filter = MOUSE_FILTER_IGNORE # Disable clicks
		else:
			print("Bench Full")
	else:
		print("Not enough gold")

func on_wave_started():
	refresh_btn.disabled = true
	expand_btn.disabled = true
	start_wave_btn.disabled = true
	start_wave_btn.text = "Fighting..."

func on_wave_ended():
	refresh_btn.disabled = false
	expand_btn.disabled = false
	start_wave_btn.disabled = false
	start_wave_btn.text = "Start Wave"
	refresh_shop(true)

func on_wave_reset():
	refresh_btn.disabled = false
	expand_btn.disabled = false
	start_wave_btn.disabled = false
	start_wave_btn.text = "Start Wave"
	# Do not refresh shop on retry

func _on_start_wave_button_pressed():
	GameManager.start_wave()

func _on_refresh_button_pressed():
	refresh_shop(false)

func _on_expand_button_pressed():
	if GameManager.grid_manager:
		GameManager.grid_manager.toggle_expansion_mode()

# Drag and Drop for Shop (Sell)
# Delegated to SellZone.gd

extends Control

# Shop Logic
var shop_items: Array = []
var shop_locked: Array = [false, false, false, false]
const SHOP_SIZE = 4

# Node References
# Updated references based on new layout
@onready var sidebar = $SidebarContainer
@onready var shop_container = $SidebarContainer/Panel/MainContainer/LeftZone/ShopContainer
@onready var refresh_btn = $SidebarContainer/Panel/MainContainer/RightZone/RefreshButton
@onready var expand_btn = $SidebarContainer/Panel/MainContainer/RightZone/ExpandButton
@onready var start_wave_btn = $SidebarContainer/Panel/MainContainer/RightZone/StartWaveButton
@onready var sell_zone_container = $SidebarContainer/Panel/MainContainer/RightZone/SellZoneContainer
@onready var gold_label = $SidebarContainer/Panel/MainContainer/LeftZone/GoldLabel
@onready var toggle_handle = $SidebarContainer/HeaderContainer/ToggleHandle

var sell_zone = null
var is_collapsed: bool = false
var sidebar_initial_y: float = 0.0

signal unit_bought(unit_key)

func _ready():
	GameManager.resource_changed.connect(update_ui)
	GameManager.wave_started.connect(on_wave_started)
	GameManager.wave_ended.connect(on_wave_ended)
	if GameManager.has_signal("wave_reset"):
		GameManager.wave_reset.connect(on_wave_reset)

	refresh_shop(true)
	update_ui()
	# update_wave_info() # Removed functionality

	expand_btn.pressed.connect(_on_expand_button_pressed)

	_create_sell_zone()
	call_deferred("_setup_collapse_handle")

	# Apply styles
	_apply_styles()

func _setup_collapse_handle():
	sidebar_initial_y = sidebar.position.y

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
	# Move sidebar down so that only the top HeaderContainer (ToggleHandle) is visible at bottom
	# ToggleHandle is in HeaderContainer which is at the top of SidebarContainer
	# To make ToggleHandle visible at bottom, we need to push Sidebar down until its top is at (ScreenBottom - ToggleHandleHeight)
	# Sidebar is anchored bottom, so its position.y is relative to anchors.
	# Actually, since Sidebar is anchored, tweening position might be tricky if anchors update.
	# But since we set anchors, position is offset.
	# Initial position (Expanded) is roughly offset_top = -height.
	# If we use position property, we are animating the offset relative to anchors or the position.
	# In Control with anchors, `position` is top-left corner relative to parent.
	# If Sidebar is Bottom-Right anchored (1, 1).
	# sidebar_initial_y is where it sits expanded.

	# Let's calculate target relative to current/initial.
	# We want the Top of Sidebar to be at Screen Bottom - Header Height.
	# Current Top is sidebar.position.y
	# Screen Bottom (relative to parent Shop) is Shop.size.y (since Shop is anchored bottom).
	# Actually Shop root has height 0 if we don't set it, but it has anchors.
	# Let's rely on sidebar size.
	# We want to move down by (Sidebar Height - Header Height).

	var header_height = $SidebarContainer/HeaderContainer.size.y
	# If Header height is 0 (due to layout), use min size of button approx 24
	if header_height < 24: header_height = 24

	var shift = sidebar.size.y - header_height
	var target_y = sidebar_initial_y + shift

	tween.tween_property(sidebar, "position:y", target_y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func expand_shop():
	if !is_collapsed: return
	is_collapsed = false
	if toggle_handle: toggle_handle.text = "▼"

	var tween = create_tween()
	tween.tween_property(sidebar, "position:y", sidebar_initial_y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _apply_styles():
	# Style Panel
	var panel = $SidebarContainer/Panel
	var panel_style = StyleBoxTexture.new()
	panel_style.texture = load("res://assets/images/UI/bg_shop.png")
	# Ensure it stretches or tiles properly if needed, but for now default.
	# Fallback or overlay for borders
	# panel_style.border_width_top = 2 # StyleBoxTexture doesn't support border directly in same way
	# panel_style.border_color = Color("#ffffff")
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
	# update_wave_info() # REMOVED

# Removed update_wave_info, get_wave_type, get_wave_icon as they were used for GlobalPreview/CurrentDetails

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
	card.custom_minimum_size = Vector2(80, 80) # Adjusted size for smaller shop
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

	if unit_key == "meat":
		# Meat special logic: Add to Inventory instead of Bench
		if GameManager.inventory_manager:
			if GameManager.gold >= proto.cost:
				if !GameManager.inventory_manager.is_full():
					if GameManager.inventory_manager.add_item({ "id": "meat", "count": 1 }):
						GameManager.spend_gold(proto.cost)
						# Meat doesn't deplete shop stock usually? Or does it?
						# Assuming shop items are one-time purchase per refresh as per card logic:
						unit_bought.emit(unit_key)
						card_ref.modulate = Color(0.5, 0.5, 0.5)
						card_ref.mouse_filter = MOUSE_FILTER_IGNORE
						print("Bought Meat")
				else:
					print("Inventory Full")
			else:
				print("Not enough gold")
		else:
			print("Inventory Manager missing")
		return

	# Standard Unit Logic
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

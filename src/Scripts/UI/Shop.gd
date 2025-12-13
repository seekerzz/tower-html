extends Control

# Shop Logic
var shop_items: Array = []
var shop_locked: Array = [false, false, false, false]
const SHOP_SIZE = 4

@onready var shop_container = $Panel/MainLayout/CoreArea/CenterWrapper/ShopContainer
@onready var bench_panel = $Panel/MainLayout/CoreArea/CenterWrapper/BenchPanel
@onready var gold_label = $Panel/MainLayout/WaveInfo/GoldLabel
@onready var refresh_btn = $Panel/MainLayout/LeftButtons/RefreshButton
@onready var expand_btn = $Panel/MainLayout/LeftButtons/ExpandButton
@onready var start_wave_btn = $Panel/MainLayout/LeftButtons/StartWaveButton
@onready var timeline_label = $Panel/MainLayout/WaveInfo/TimelineLabel
@onready var details_label = $Panel/MainLayout/WaveInfo/DetailsLabel
@onready var sell_zone = $Panel/MainLayout/SellZone
@onready var toggle_handle = $Panel/ToggleHandle

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

	panel_initial_y = $Panel.position.y
	_setup_sell_zone_visuals()
	_setup_bench_visuals()

func _setup_bench_visuals():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.3)
	style.set_corner_radius_all(10)
	bench_panel.add_theme_stylebox_override("panel", style)

func _setup_sell_zone_visuals():
	# Configure visual style for Sell Zone (Big Rounded Rect)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 0.3, 0.3, 0.2)
	style.set_corner_radius_all(20)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 0, 0, 0.5)
	sell_zone.add_theme_stylebox_override("panel", style)

	# Ensure label exists or add one if needed, though TSCN uses PanelContainer.
	# The script SellZone.gd attached to it might handle drop logic.
	# Let's add a label to it for clarity if it doesn't have one.
	if sell_zone.get_child_count() == 0:
		var lbl = Label.new()
		lbl.text = "💰\nSELL"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 20)
		sell_zone.add_child(lbl)

func _on_toggle_handle_pressed():
	if is_collapsed:
		expand_shop()
	else:
		collapse_shop()

func collapse_shop():
	if is_collapsed: return
	is_collapsed = true
	toggle_handle.text = "▲"

	var tween = create_tween()
	# Move panel down so only handle is visible at bottom
	# When collapsed, Panel moves down by its height.
	# The Handle is at y = -24 (above panel).
	# We want Handle to be at Screen Bottom - 24.
	# If Panel is at Screen Bottom (Anchor Bottom=1), its y is usually 0 relative to parent if parent is screen?
	# Shop.gd is Control, anchors 12 (bottom wide), offset_top = -220.
	# So Panel is child of Shop. Shop moves? No, $Panel moves relative to Shop.
	# Shop is at Bottom.
	# If we move Panel down by Panel.size.y, it goes offscreen.
	# The handle is attached to Panel.
	# Wait, toggle logic failed because handle moved offscreen or behind something?
	# Or maybe `panel_initial_y` was wrong?

	# Let's verify coordinates. Shop is anchored bottom. Panel is fill.
	# If Shop height is 220.
	# We want to slide it down so top edge is at bottom of screen.
	# Shop node itself can slide? Or just Panel? Script slides Panel.
	# Panel is Anchor 15 (Fill).
	# If we change position:y of Panel, we break anchors unless we change offset.
	# It's better to tween the Shop (Control) offset or position?
	# But script moves $Panel.
	# Let's stick to moving Panel but ensure we don't move it too far.

	# Current Logic: target_y = initial + size.y.
	# If initial is 0 (relative to Shop), target is 220.
	# Handle is at -24. So Handle is at 196 (relative to Shop).
	# Shop is at Bottom of screen. 196 is inside Shop area? No, Shop is height 220.
	# 196 is visible.

	# Issue: "Expand" button (ToggleHandle) click ineffective?
	# Maybe `_on_toggle_handle_pressed` is not firing?
	# Or `is_collapsed` logic?
	# Maybe it's blocked by `SellZone` or something?
	# I'll ensure Z-Index or draw order. Handle is added in Scene now.
	# Handle is child of Panel.

	var target_y = $Panel.size.y
	tween.tween_property($Panel, "position:y", target_y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func expand_shop():
	if !is_collapsed: return
	is_collapsed = false
	toggle_handle.text = "▼"

	var tween = create_tween()
	tween.tween_property($Panel, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Update styles
	update_button_styles()

func update_button_styles():
	apply_button_style(refresh_btn, Color("#3498db")) # Blue
	apply_button_style(expand_btn, Color("#2ecc71")) # Green
	apply_button_style(start_wave_btn, Color("#e74c3c"), true) # Red

func apply_button_style(button: Button, color: Color, is_main_action: bool = false):
	var corner_radius = 12 if is_main_action else 10

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

	button.add_theme_font_size_override("font_size", 32) # Emoji size

func update_ui():
	gold_label.text = "💰 %d" % GameManager.gold
	update_wave_info()

func update_wave_info():
	if !GameManager.combat_manager: return

	# Global Preview (Timeline)
	var timeline_text = ""
	var current_wave = GameManager.wave
	# Show NEXT 5 waves (timeline usually shows future)
	# But user says "preview didn't match actual enemies".
	# The details label shows CURRENT wave.
	# The timeline shows FUTURE.
	# Let's check logic for current wave detail.

	for i in range(1, 6):
		var w = current_wave + i
		var type = GameManager.combat_manager.get_wave_type(w)
		var icon = "?"
		if Constants.ENEMY_VARIANTS.has(type):
			icon = Constants.ENEMY_VARIANTS[type].icon
		elif type == 'event':
			icon = "⚠️"
		elif type == 'boss':
			icon = "👹"
		timeline_text += icon + " "

	timeline_label.text = timeline_text.strip_edges()

	# Current Wave Details
	var preview = GameManager.combat_manager.get_wave_preview(current_wave)
	var type_key = preview.type
	var count = preview.count

	# Resolve event/boss specific icon/text
	var display_icon = "❓"
	var display_name = type_key.capitalize()

	if Constants.ENEMY_VARIANTS.has(type_key):
		display_icon = Constants.ENEMY_VARIANTS[type_key].icon
		display_name = Constants.ENEMY_VARIANTS[type_key].name
	elif type_key == 'event':
		display_icon = "⚠️"
		display_name = "Event"
	elif type_key == 'boss':
		display_icon = "👹"
		display_name = "Boss"

	details_label.text = "[center]%s x%d\n%s[/center]" % [display_icon, count, display_name]

	# Trigger wave info update more frequently?
	# Added to _process or connect to more signals if needed.
	# But "preview didn't match" might be due to CombatManager logic.
	# We rely on CombatManager.get_wave_preview matching start_wave_logic.

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

	# Re-apply styles after refresh logic if needed
	update_button_styles()

func create_shop_card(index, unit_key):
	var card = ShopCard.new()
	card.setup(unit_key)
	card.custom_minimum_size = Vector2(100, 120)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL

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
	start_wave_btn.text = "🚫" # Locked/Fighting
	collapse_shop()

func on_wave_ended():
	refresh_btn.disabled = false
	expand_btn.disabled = false
	start_wave_btn.disabled = false
	start_wave_btn.text = "⚔️"
	refresh_shop(true)
	expand_shop()

func on_wave_reset():
	refresh_btn.disabled = false
	expand_btn.disabled = false
	start_wave_btn.disabled = false
	start_wave_btn.text = "⚔️"

func _on_start_wave_button_pressed():
	GameManager.start_wave()

func _on_refresh_button_pressed():
	refresh_shop(false)

func _on_expand_button_pressed():
	if GameManager.grid_manager:
		GameManager.grid_manager.toggle_expansion_mode()

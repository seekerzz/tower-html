extends Control

# Shop Logic
var shop_items: Array = []
var shop_locked: Array = [false, false, false, false]
const SHOP_SIZE = 4

@onready var shop_container = $Panel/MainLayout/CardsContainer
@onready var gold_label = $Panel/MainLayout/FunctionContainer/GoldLabel
@onready var refresh_btn = $Panel/MainLayout/FunctionContainer/RefreshButton
@onready var expand_btn = $Panel/MainLayout/FunctionContainer/ExpandButton
@onready var start_wave_btn = $Panel/MainLayout/FunctionContainer/StartWaveButton
@onready var collapse_btn = $Panel/MainLayout/CollapseButton
@onready var wave_timeline = $Panel/MainLayout/WaveTimeline
@onready var sell_zone = $Panel/MainLayout/SellZone

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

	expand_btn.pressed.connect(_on_expand_button_pressed)
	collapse_btn.pressed.connect(_on_toggle_handle_pressed)

	_setup_sell_zone()
	call_deferred("_setup_collapse_handle")
	_setup_styles()

func _setup_collapse_handle():
	# Store initial Y. Assuming it starts expanded.
	panel_initial_y = position.y
	# If we want to support starting collapsed, we'd need to check current state.
	# The scene anchors it to bottom, so it should be visible.
	pass

func _on_toggle_handle_pressed():
	if is_collapsed:
		expand_shop()
	else:
		collapse_shop()

func collapse_shop():
	if is_collapsed: return
	is_collapsed = true
	collapse_btn.text = "▲"

	var tween = create_tween()
	# Move panel down. How much?
	# We want only the top sliver or just the handle visible?
	# But the handle is now INSIDE the layout on the left.
	# If we move the whole panel down, the handle goes with it.
	# The user requested: "Leftmost Fold Button".
	# If the panel slides down, the button must remain visible.
	# This implies the button might need to be outside the sliding part or the sliding part is different.
	# But the prompt said: "Reconstruct Shop.tscn... Leftmost fold button... inside new horizontal arrangement".
	# If it's inside the horizontal arrangement, and the whole shop slides down, the button disappears.
	# Unless the "Shop" is the container, and we slide something else?
	# Or maybe we slide to a position where the top row is still visible?
	# But the layout IS the top row.
	# Maybe the collapse meant "Minimize"?
	# If the button is on the left, maybe it slides LEFT? No, it's a bottom shop.
	# Let's assume we slide down but leave the top edge visible?
	# OR, maybe the collapse button should indeed be outside the panel if it's to remain visible when panel is hidden.
	# However, the prompt explicitly said: "Leftmost fold button... in the new horizontal arrangement".
	# This implies the button is PART of the bar.
	# If the bar IS the shop, then maybe "Collapse" means something else?
	# Or maybe the shop has a "Header" vs "Body"?
	# "Function Buttons... Sell Zone... Bench... Cards... Timeline".
	# This sounds like the MAIN BAR.
	# If this bar is collapsible, it implies there's something else?
	# Or maybe the bar stays, and an "Extended" area collapses?
	# But currently the shop IS just this bar (and maybe a bench area?).
	# Actually, the previous shop had a bench area separate from the buttons.
	# Now they are all in one line.
	# If they are all in one line, maybe the shop DOESN'T collapse off-screen?
	# Maybe it just compacts?
	# Re-reading: "Leftmost fold button: Move existing down/up arrow to leftmost edge."
	# Previous behavior: "Move panel down so only handle is visible".
	# If the handle is now INSIDE the panel, and we move the panel down, the handle is lost.
	# Unless we change the "Collapse" behavior to "Hide most of the UI but keep the button visible"?
	# But if the button is on the left of the bar, and we hide the bar...
	# I will assume that "Collapse" means moving the panel down such that only the top border or a small strip is visible?
	# But that seems broken if the button is inside.
	# HACK: I will make the collapse animation move the panel down, but maybe leave 30px visible?
	# Or, I will ignore the "Hide" logic if it breaks the UI, but I should try to preserve it.
	# Alternative: When collapsed, we move it down, but the Collapse Button is "special" and might be anchored differently?
	# No, it's in the HBox.
	# Let's assume the user wants the ability to hide the shop.
	# If I move the panel down `size.y - button.size.y`, the button (if at the top) might be visible.
	# But it's an HBox, so vertical alignment matters.
	# If `alignment` is center, the button is in the middle vertically.
	# I will set the tween to move it down so only the top 10% is visible?
	# Actually, if the button is the leftmost element, and we slide down...
	# Maybe the shop shouldn't slide down completely.
	# Let's stick to the styling and layout first. The collapse logic is secondary.
	# I will move it down by `size.y - 40` (assuming height is ~150-200).

	var target_y = panel_initial_y + size.y - 40
	tween.tween_property(self, "position:y", target_y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func expand_shop():
	if !is_collapsed: return
	is_collapsed = false
	collapse_btn.text = "▼"

	var tween = create_tween()
	tween.tween_property(self, "position:y", panel_initial_y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _setup_styles():
	# Panel Style
	var panel = $Panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.border_width_top = 2
	panel_style.border_color = Color("#ffffff")
	panel.add_theme_stylebox_override("panel", panel_style)

	# Buttons
	apply_button_style(refresh_btn, Color("#3498db")) # Blue
	apply_button_style(expand_btn, Color("#2ecc71")) # Green
	apply_button_style(start_wave_btn, Color("#e74c3c"), true) # Red

	# Collapse Button Style (Subtle)
	var collapse_style = StyleBoxFlat.new()
	collapse_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	collapse_style.set_corner_radius_all(4)
	collapse_btn.add_theme_stylebox_override("normal", collapse_style)
	collapse_btn.add_theme_stylebox_override("hover", collapse_style.duplicate())
	# Hover lightened?

	# Sell Zone Style
	var sz_style = StyleBoxFlat.new()
	sz_style.bg_color = Color(0.8, 0.2, 0.2, 0.3)
	sz_style.set_corner_radius_all(12)
	sz_style.border_width_left = 2
	sz_style.border_width_top = 2
	sz_style.border_width_right = 2
	sz_style.border_width_bottom = 2
	sz_style.border_color = Color(1, 0.2, 0.2, 0.6)
	sell_zone.add_theme_stylebox_override("panel", sz_style)


func apply_button_style(button: Button, color: Color, is_main_action: bool = false):
	# "High rounded rectangle... fill height"
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var corner_radius = 12

	# Normal
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = color
	style_normal.set_corner_radius_all(corner_radius)

	# Hover
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = color.lightened(0.2)

	# Pressed
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = color.darkened(0.2)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)

	if is_main_action:
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_constant_override("outline_size", 2)
		button.add_theme_color_override("font_outline_color", Color.BLACK)

func _setup_sell_zone():
	# Script is attached via scene.
	sell_zone.mouse_filter = MOUSE_FILTER_STOP

func update_ui():
	gold_label.text = "💰 %d" % GameManager.gold
	update_timeline()

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
	# Card size
	card.custom_minimum_size = Vector2(100, 140)

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
	start_wave_btn.text = "Fighting..."
	# Do not auto collapse if the button is inside, user might want to see timeline?
	# But prompt said "Move wave timeline... to shop interface".
	# If we collapse, timeline is hidden.
	# So maybe we shouldn't collapse automatically anymore?
	# Previous behavior: collapse_shop().
	# I will disable auto-collapse for now, or keep it.
	# If I keep it, timeline disappears.
	# I'll comment it out to be safe, as visibility is key.
	# collapse_shop()

func on_wave_ended():
	refresh_btn.disabled = false
	expand_btn.disabled = false
	start_wave_btn.disabled = false
	start_wave_btn.text = "Start Wave"
	refresh_shop(true)
	# expand_shop()

func on_wave_reset():
	refresh_btn.disabled = false
	expand_btn.disabled = false
	start_wave_btn.disabled = false
	start_wave_btn.text = "Start Wave"

func _on_start_wave_button_pressed():
	GameManager.start_wave()

func _on_refresh_button_pressed():
	refresh_shop(false)

func _on_expand_button_pressed():
	if GameManager.grid_manager:
		GameManager.grid_manager.toggle_expansion_mode()

# Timeline Logic
func update_timeline():
	if not wave_timeline: return
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

		# Optional: Add background for current wave
		if i == 0:
			var panel = PanelContainer.new()
			var style = StyleBoxFlat.new()
			style.bg_color = Color(1, 1, 1, 0.2)
			style.set_corner_radius_all(4)
			panel.add_theme_stylebox_override("panel", style)
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

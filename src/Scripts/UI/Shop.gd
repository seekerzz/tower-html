extends Control

# Shop Logic
var shop_items: Array = []
var shop_locked: Array = [false, false, false, false]
const SHOP_SIZE = 4

@onready var shop_container = $Panel/ShopContainer
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

func _create_sell_zone():
	# Create a visual area for selling
	sell_zone = PanelContainer.new()
	sell_zone.set_script(load("res://src/Scripts/UI/SellZone.gd"))
	var lbl = Label.new()
	lbl.text = "SELL\nZONE"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sell_zone.add_child(lbl)

	# Place it at the bottom of the sidebar or side of it
	$Panel.add_child(sell_zone)
	# In vertical layout, maybe above the refresh button or at the very bottom
	sell_zone.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	# Adjust position based on new layout.
	# Shop width is ~140. Let's put it near bottom, above expand button maybe?
	# Or let's put it to the RIGHT of the shop panel (offset x = 140)
	sell_zone.position = Vector2(150, get_viewport_rect().size.y - 120)
	# Wait, get_viewport_rect might not be reliable in ready if not resized.
	# Better to anchor it relative to parent if parent is full screen.
	# But parent is Shop (width 140).
	# Let's put it inside the Panel but at the bottom, above buttons?
	# Or beside the bench.

	# Current plan: Put it near the bench (which is at bottom left, offset from shop).
	# Bench is at x=160.
	# Let's put SellZone at x=160, y=Bottom-100?

	sell_zone.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	# Use offsets since anchors are set to Bottom Left.
	# Anchor Bottom means Y=ParentHeight. Refresh button is at -120.
	# SellZone height is 60. To avoid overlap and add spacing (10px):
	# Bottom of SellZone should be at -130. Top = -130 - 60 = -190.
	sell_zone.offset_left = 10
	sell_zone.offset_top = -190
	sell_zone.offset_bottom = -130
	sell_zone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_zone.custom_minimum_size = Vector2(120, 60)

	sell_zone.modulate = Color(1, 0.5, 0.5)
	sell_zone.mouse_filter = MOUSE_FILTER_STOP

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

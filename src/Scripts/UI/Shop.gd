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

	# Place it to the right of bench or somewhere prominent
	$Panel.add_child(sell_zone)
	sell_zone.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	sell_zone.position = Vector2($Panel.size.x - 100, 20)
	sell_zone.custom_minimum_size = Vector2(80, 80)
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
	var proto = Constants.UNIT_TYPES[unit_key]
	var btn = Button.new()
	btn.text = "%s\n%s\n%d💰" % [proto.icon, proto.name, proto.cost]
	btn.custom_minimum_size = Vector2(80, 100)
	btn.pressed.connect(func(): buy_unit(index, unit_key, btn))

	# Connect Tooltip signals
	btn.mouse_entered.connect(func():
		var stats = {
			"damage": proto.damage,
			"range": proto.range,
			"atk_speed": proto.get("atkSpeed", proto.get("atk_speed", 1.0))
		}
		GameManager.show_tooltip.emit(proto, stats, [], btn.get_global_mouse_position())
	)
	btn.mouse_exited.connect(func(): GameManager.hide_tooltip.emit())

	shop_container.add_child(btn)

func buy_unit(index, unit_key, button_ref):
	if GameManager.is_wave_active: return
	var proto = Constants.UNIT_TYPES[unit_key]
	if GameManager.gold >= proto.cost:
		if GameManager.main_game and GameManager.main_game.add_to_bench(unit_key):
			GameManager.spend_gold(proto.cost)
			unit_bought.emit(unit_key)
			# Disable button
			button_ref.disabled = true
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

func _on_start_wave_button_pressed():
	GameManager.start_wave()

func _on_refresh_button_pressed():
	refresh_shop(false)

func _on_expand_button_pressed():
	if GameManager.grid_manager:
		# GameManager.grid_manager.toggle_expansion_mode()
		pass

# Drag and Drop for Shop (Sell)
# Delegated to SellZone.gd

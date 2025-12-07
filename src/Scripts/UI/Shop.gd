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
@onready var bench_container = $Panel/BenchContainer

signal unit_bought(unit_key)

const BENCH_UNIT_SCRIPT = preload("res://src/Scripts/UI/BenchUnit.gd")
const SELL_SLOT_SCRIPT = preload("res://src/Scripts/UI/SellSlot.gd")

func _ready():
	GameManager.resource_changed.connect(update_ui)
	GameManager.wave_started.connect(on_wave_started)
	GameManager.wave_ended.connect(on_wave_ended)
	refresh_shop(true)
	update_ui()

	_create_sell_slot()

func _create_sell_slot():
	var sell = Panel.new()
	sell.set_script(SELL_SLOT_SCRIPT)
	# Position it somewhere? e.g. right side of panel
	sell.position = Vector2(900, 20) # Approximate, layout depends on scene
	# Or add to Panel
	$Panel.add_child(sell)
	sell.anchors_preset = Control.PRESET_CENTER_RIGHT
	sell.position.x -= 100

func update_ui():
	gold_label.text = "💰 %d" % GameManager.gold

func update_bench_ui(bench_data: Array):
	for child in bench_container.get_children():
		child.queue_free()

	for i in range(bench_data.size()):
		var data = bench_data[i]
		if data != null:
			var item = Control.new()
			item.set_script(BENCH_UNIT_SCRIPT)
			item.setup(data.key, i)
			bench_container.add_child(item)
		else:
			var placeholder = Control.new()
			placeholder.custom_minimum_size = Vector2(60, 60)
			var rect = ColorRect.new()
			rect.color = Color(0, 0, 0, 0.3)
			rect.anchors_preset = 15
			placeholder.add_child(rect)
			bench_container.add_child(placeholder)

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
	shop_container.add_child(btn)

func buy_unit(index, unit_key, btn: Button):
	if GameManager.is_wave_active: return
	var proto = Constants.UNIT_TYPES[unit_key]
	if GameManager.gold >= proto.cost:
		if GameManager.main_game and GameManager.main_game.add_to_bench(unit_key):
			GameManager.spend_gold(proto.cost)
			unit_bought.emit(unit_key)
			btn.disabled = true # Disable button
		else:
			print("Bench Full or MainGame missing")
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
	# Trigger GridManager expand mode
	if GameManager.grid_manager:
		GameManager.grid_manager.toggle_expand_mode()

# Drag Drop Support for Bench Area
func _can_drop_data(_at_position, data):
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "grid_unit":
		return true
	return false

func _drop_data(_at_position, data):
	var unit = data.unit
	# Check if dropped on SellSlot? SellSlot handles its own drops if it's on top.
	# If we are here, it wasn't caught by SellSlot (or SellSlot didn't consume it? No, drop consumes).
	# So we treat this as "Drop on Shop" -> Bench.

	if GameManager.main_game.try_add_to_bench_from_grid(unit):
		return # Success
	else:
		# Failed to bench (full?)
		# Unit stays on grid (UnitDragHandler handles visibility restore)
		pass

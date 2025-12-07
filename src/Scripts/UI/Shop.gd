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

func _ready():
	GameManager.resource_changed.connect(update_ui)
	GameManager.wave_started.connect(on_wave_started)
	GameManager.wave_ended.connect(on_wave_ended)
	refresh_shop(true)
	update_ui()
	# Initial Bench UI update handled by MainGame calling update_bench_ui or we can trigger it

func update_ui():
	gold_label.text = "💰 %d" % GameManager.gold

func update_bench_ui(bench_data: Array):
	# Clear bench
	for child in bench_container.get_children():
		child.queue_free()

	# Rebuild bench
	for i in range(bench_data.size()):
		var data = bench_data[i]
		if data != null:
			var item = Control.new() # Use a container or our BenchUnit
			# Actually we want our BenchUnit
			item = Control.new()
			item.set_script(BENCH_UNIT_SCRIPT)
			# Need to set properties before ready or use setup
			# script is set, but not ready yet.
			item.setup(data.key, i)
			bench_container.add_child(item)
		else:
			# Placeholder
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

	# Clear previous UI
	for child in shop_container.get_children():
		child.queue_free()

	# Create new UI
	for i in range(SHOP_SIZE):
		create_shop_card(i, shop_items[i])

func create_shop_card(index, unit_key):
	var proto = Constants.UNIT_TYPES[unit_key]
	var btn = Button.new()
	btn.text = "%s\n%s\n%d💰" % [proto.icon, proto.name, proto.cost]
	btn.custom_minimum_size = Vector2(80, 100)
	btn.pressed.connect(func(): buy_unit(index, unit_key))
	shop_container.add_child(btn)

func buy_unit(index, unit_key):
	if GameManager.is_wave_active: return
	var proto = Constants.UNIT_TYPES[unit_key]
	if GameManager.gold >= proto.cost:
		# Call MainGame to add to bench
		if GameManager.main_game and GameManager.main_game.add_to_bench(unit_key):
			GameManager.spend_gold(proto.cost)
			unit_bought.emit(unit_key)
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

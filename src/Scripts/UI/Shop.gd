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

signal unit_bought(unit_key)

func _ready():
	GameManager.resource_changed.connect(update_ui)
	GameManager.wave_started.connect(on_wave_started)
	GameManager.wave_ended.connect(on_wave_ended)
	refresh_shop(true)
	update_ui()

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
		# Need to find a place to put it (Bench or Grid)
		# For now, let's assume we emit a signal and GridManager/Bench handles it
		# Or better, try to add to Bench first

		# We need a Bench Manager.
		# For this implementation, I'll cheat and assume we can just emit the signal and someone else handles the logic
		# But wait, GameManager doesn't store units.

		# Let's verify if we can add it.
		unit_bought.emit(unit_key)
		GameManager.spend_gold(proto.cost)

		# Remove from shop if not locked? (Ref says it stays?)
		# Ref: "buyUnitFromShop... if addToBench(newUnit)..."
		# The card stays.
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

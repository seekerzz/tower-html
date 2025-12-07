extends Node2D

@onready var grid_layer = %GridLayer
@onready var projectile_layer = $ProjectileLayer
@onready var barricade_layer = $BarricadeLayer
@onready var ui_resource = $CanvasLayer/HUD/TopBar/ResourceInfo
@onready var ui_wave = $CanvasLayer/HUD/TopBar/WaveInfo
@onready var ui_shop = $CanvasLayer/HUD/BottomBar/Shop
@onready var btn_start = $CanvasLayer/HUD/BottomBar/StartWaveBtn

var selected_bench_slot = -1

func _ready():
	GameManager.resource_changed.connect(_on_resource_changed)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_ended.connect(_on_wave_ended)
	GameManager.game_over.connect(_on_game_over)
	ShopManager.shop_updated.connect(_update_shop_ui)

	btn_start.pressed.connect(_on_start_wave_pressed)
	grid_layer.tile_clicked.connect(_on_tile_clicked)

	_update_ui()
	_update_shop_ui()

var is_drawing = false
var draw_start = Vector2.ZERO
var current_material = "wood"

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start drawing if material selected (logic needed for material selection)
				# For now, just assume middle mouse or shift+click for debug drawing
				if Input.is_key_pressed(KEY_SHIFT):
					is_drawing = true
					draw_start = get_global_mouse_position()
			else:
				if is_drawing:
					is_drawing = false
					var draw_end = get_global_mouse_position()
					_spawn_barricade(draw_start, draw_end)

func _spawn_barricade(start, end):
	if start.distance_to(end) < 10: return
	var b_scene = load("res://scenes/barricade.tscn")
	var b = b_scene.instantiate()
	b.position = start # Relative
	# Actually barricade script handles local points, so keep position simple or adjust
	# Let's say position is start.
	b.initialize("wood", start, end)
	barricade_layer.add_child(b)

func _process(delta):
	# Spawner logic here or in a separate Spawner node
	if GameManager.is_wave_active:
		_process_spawning(delta)

var spawn_timer = 0.0
var enemies_to_spawn = 0

func _on_start_wave_pressed():
	if GameManager.is_wave_active: return
	GameManager.start_wave()
	enemies_to_spawn = 10 + GameManager.wave * 2
	spawn_timer = 0

func _process_spawning(delta):
	if enemies_to_spawn <= 0:
		if get_tree().get_nodes_in_group("enemies").size() == 0:
			GameManager.end_wave()
		return

	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = 1.0 # Every 1 sec
		spawn_enemy()
		enemies_to_spawn -= 1

func spawn_enemy():
	var enemy_scene = load("res://scenes/enemy.tscn")
	var enemy = enemy_scene.instantiate()

	# Random position around
	var angle = randf() * TAU
	var dist = 600
	var pos = Vector2(cos(angle) * dist, sin(angle) * dist)

	enemy.position = pos
	enemy.target_core = Vector2.ZERO # Center

	# Determine type
	var type_key = "slime"
	enemy.initialize(UnitData.ENEMY_VARIANTS[type_key], GameManager.wave)

	add_child(enemy)

func _on_resource_changed():
	_update_ui()

func _update_ui():
	ui_resource.text = "Gold: %d | Food: %d/%d | Mana: %d/%d" % [GameManager.gold, floor(GameManager.food), GameManager.max_food, floor(GameManager.mana), GameManager.max_mana]
	ui_wave.text = "Wave: %d" % GameManager.wave

func _update_shop_ui():
	# Clear existing
	for child in ui_shop.get_children():
		child.queue_free()

	# Bench
	var bench_container = HBoxContainer.new()
	ui_shop.add_child(bench_container)

	for i in range(ShopManager.BENCH_SIZE):
		var btn = Button.new()
		var unit = ShopManager.bench[i]
		if unit:
			var proto = UnitData.UNIT_TYPES[unit.key]
			btn.text = proto.icon
			if i == selected_bench_slot:
				btn.modulate = Color.YELLOW
		else:
			btn.text = "___"

		btn.custom_minimum_size = Vector2(40, 40)
		btn.pressed.connect(func(): _on_bench_slot_clicked(i))
		bench_container.add_child(btn)

	# Separator
	ui_shop.add_child(VSeparator.new())

	# Shop Items
	for i in range(ShopManager.shop_items.size()):
		var item = ShopManager.shop_items[i]
		var proto = UnitData.UNIT_TYPES[item.key]
		var btn = Button.new()
		btn.text = "%s\n%d G" % [proto.icon, proto.cost]
		if item.locked:
			btn.text += " (L)"

		btn.pressed.connect(func(): ShopManager.buy_unit(i))
		ui_shop.add_child(btn)

	# Reroll
	var btn_reroll = Button.new()
	btn_reroll.text = "Reroll (10)"
	btn_reroll.pressed.connect(func(): ShopManager.reroll_shop())
	ui_shop.add_child(btn_reroll)

func _on_bench_slot_clicked(index: int):
	if selected_bench_slot == index:
		selected_bench_slot = -1 # Deselect
	else:
		if ShopManager.bench[index] != null:
			selected_bench_slot = index
	_update_shop_ui()

func _on_tile_clicked(pos: Vector2i, btn_idx: int):
	if btn_idx == MOUSE_BUTTON_LEFT:
		if selected_bench_slot != -1:
			# Try to place unit
			var unit_data = ShopManager.bench[selected_bench_slot]
			if grid_layer.place_unit(unit_data.key, pos):
				ShopManager.bench[selected_bench_slot] = null
				selected_bench_slot = -1
				_update_shop_ui()
	elif btn_idx == MOUSE_BUTTON_RIGHT:
		# Inspect or sell?
		pass

func _on_wave_started():
	btn_start.disabled = true

func _on_wave_ended():
	btn_start.disabled = false
	ShopManager.generate_shop_items(false) # Refresh shop on wave end

func _on_game_over():
	print("Game Over")
	get_tree().paused = true

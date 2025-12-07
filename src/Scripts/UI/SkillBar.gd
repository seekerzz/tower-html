extends Control

@onready var container = $PanelContainer/HBoxContainer

var skill_units = []

func _ready():
	# Wait for grid to be ready
	await get_tree().create_timer(0.1).timeout

	if GameManager.grid_manager:
		if !GameManager.grid_manager.grid_updated.is_connected(refresh_skills):
			GameManager.grid_manager.grid_updated.connect(refresh_skills)

	refresh_skills()
	GameManager.unit_purchased.connect(func(_u): refresh_skills())
	GameManager.unit_sold.connect(func(_u): refresh_skills())

func refresh_skills():
	# Clear existing
	for child in container.get_children():
		child.queue_free()
	skill_units.clear()

	if !GameManager.grid_manager: return

	# Scan grid for units with skills
	var units_with_skills = []
	for key in GameManager.grid_manager.tiles:
		var tile = GameManager.grid_manager.tiles[key]
		if tile.unit and tile.unit.unit_data.has("skill"):
			units_with_skills.append(tile.unit)

	# Create buttons
	var hotkeys = ["Q", "W", "E", "R"]
	for i in range(min(units_with_skills.size(), 4)):
		var unit = units_with_skills[i]
		skill_units.append(unit)

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(60, 60)
		btn.text = "%s\n%s" % [unit.unit_data.skill.capitalize(), hotkeys[i]]
		btn.pressed.connect(func(): _on_skill_btn_pressed(unit))

		# Cooldown overlay (using ProgressBar)
		var cd_bar = TextureProgressBar.new()
		cd_bar.name = "CD"
		cd_bar.fill_mode = TextureProgressBar.FILL_CLOCKWISE
		cd_bar.value = 0
		cd_bar.max_value = 100
		cd_bar.step = 0.1
		cd_bar.modulate = Color(0, 0, 0, 0.5)
		cd_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# We need a texture for the progress bar to show up
		var placeholder = PlaceholderTexture2D.new()
		placeholder.size = Vector2(1,1)
		cd_bar.texture_progress = placeholder

		btn.add_child(cd_bar)
		container.add_child(btn)

func _process(_delta):
	for i in range(skill_units.size()):
		var unit = skill_units[i]
		var btn = container.get_child(i)
		var cd_bar = btn.get_node("CD")

		# Update CD visual
		if unit.skill_cooldown > 0:
			var max_cd = unit.unit_data.get("skillCd", 10.0)
			cd_bar.value = (unit.skill_cooldown / max_cd) * 100
			btn.disabled = true
		else:
			cd_bar.value = 0
			btn.disabled = false

		# Update Mana visual (disable if no mana)
		if GameManager.mana < unit.skill_mana_cost:
			btn.modulate = Color(0.5, 0.5, 0.5)
		else:
			btn.modulate = Color.WHITE

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and !event.echo:
		var index = -1
		match event.keycode:
			KEY_Q: index = 0
			KEY_W: index = 1
			KEY_E: index = 2
			KEY_R: index = 3

		if index != -1 and index < skill_units.size():
			_on_skill_btn_pressed(skill_units[index])

func _on_skill_btn_pressed(unit):
	unit.activate_skill()

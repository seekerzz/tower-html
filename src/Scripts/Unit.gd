extends Node2D

var type_key: String
var level: int = 1
var stats_multiplier: float = 1.0
var cooldown: float = 0.0
var skill_cooldown: float = 0.0
var active_buffs: Array = []
var traits: Array = []
var unit_data: Dictionary

# Stats
var damage: float
var range_val: float
var atk_speed: float
var attack_cost_food: float = 0.0
var attack_cost_mana: float = 0.0
var skill_mana_cost: float = 30.0

var is_starving: bool = false
var is_no_mana: bool = false
var crit_rate: float = 0.0
var bounce_count: int = 0
var split_count: int = 0

# Grid
var grid_pos: Vector2i = Vector2i.ZERO

signal unit_clicked(unit)

const DRAG_HANDLER_SCRIPT = preload("res://src/Scripts/UI/UnitDragHandler.gd")

func setup(key: String):
	type_key = key
	unit_data = Constants.UNIT_TYPES[key].duplicate()
	reset_stats()
	update_visuals()
	_setup_drag_handler()

func _setup_drag_handler():
	# Create a Control to handle drag and drop
	var drag = Control.new()
	drag.name = "DragHitbox"
	drag.set_script(DRAG_HANDLER_SCRIPT)
	drag.unit = self

	# Size matches the unit visual rect
	var size = unit_data.size
	drag.size = Vector2(size.x * 60 - 4, size.y * 60 - 4)
	drag.position = -drag.size / 2 # Centered

	# Add on top of everything
	add_child(drag)

func reset_stats():
	damage = unit_data.damage
	range_val = unit_data.range
	atk_speed = unit_data.atk_speed if "atk_speed" in unit_data else unit_data.get("atkSpeed", 1.0)
	crit_rate = 0.0
	bounce_count = 0
	split_count = 0
	active_buffs.clear()

	attack_cost_food = unit_data.get("foodCost", 1.0)
	attack_cost_mana = unit_data.get("manaCost", 0.0)
	skill_mana_cost = unit_data.get("skillCost", 30.0)

	update_visuals()
	if level > 1:
		damage *= pow(1.5, level - 1)

func apply_buff(buff_type: String):
	if buff_type in active_buffs: return
	active_buffs.append(buff_type)

	match buff_type:
		"range":
			range_val *= 1.25
		"speed":
			atk_speed *= 1.2
		"crit":
			crit_rate += 0.25
		"bounce":
			bounce_count += 1
		"split":
			split_count += 1

func activate_skill():
	if !unit_data.has("skill"): return

	if skill_cooldown > 0:
		return

	if GameManager.consume_resource("mana", skill_mana_cost):
		is_no_mana = false
		skill_cooldown = unit_data.get("skillCd", 10.0)

		var skill_name = unit_data.skill
		GameManager.spawn_floating_text(global_position, skill_name.capitalize() + "!", Color.CYAN)

		var tween = create_tween()
		tween.tween_property($ColorRect, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property($ColorRect, "scale", Vector2(1.0, 1.0), 0.1)

	else:
		is_no_mana = true
		GameManager.spawn_floating_text(global_position, "No Mana!", Color.BLUE)

func update_visuals():
	$Label.text = unit_data.icon
	var size = unit_data.size
	$ColorRect.size = Vector2(size.x * 60 - 4, size.y * 60 - 4)
	$ColorRect.position = -($ColorRect.size / 2)
	$Label.position = $ColorRect.position
	$Label.size = $ColorRect.size

	if level > 1:
		$StarLabel.text = "⭐%d" % level
		$StarLabel.show()
	else:
		$StarLabel.hide()

	_update_buff_icons()

func _update_buff_icons():
	var buff_container = get_node_or_null("BuffContainer")
	if !buff_container:
		buff_container = HBoxContainer.new()
		buff_container.name = "BuffContainer"
		buff_container.alignment = BoxContainer.ALIGNMENT_CENTER
		buff_container.position = Vector2(-$ColorRect.size.x/2, $ColorRect.size.y/2 - 15)
		buff_container.size = Vector2($ColorRect.size.x, 15)
		buff_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(buff_container)

	for child in buff_container.get_children():
		child.queue_free()

	for buff in active_buffs:
		var lbl = Label.new()
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var icon = "?"
		match buff:
			"fire": icon = "🔥"
			"poison": icon = "🧪"
			"range": icon = "🔭"
			"speed": icon = "⚡"
			"crit": icon = "💥"
			"bounce": icon = "🪞"
			"split": icon = "💠"

		lbl.text = icon
		buff_container.add_child(lbl)

func _process(delta):
	if !GameManager.is_wave_active: return

	if cooldown > 0:
		cooldown -= delta

	if skill_cooldown > 0:
		skill_cooldown -= delta

	if is_starving:
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	elif is_no_mana and unit_data.has("skill"):
		modulate = Color(0.7, 0.7, 1.0, 1.0)
	else:
		modulate = Color.WHITE

func merge_with(other_unit):
	level += 1
	update_visuals()

func devour(food_unit):
	level += 1
	damage += 5
	stats_multiplier += 0.2
	update_visuals()

# Tooltip logic called by UnitDragHandler (Control)
func _on_mouse_entered_control():
	var current_stats = {
		"damage": damage,
		"range": range_val,
		"atk_speed": atk_speed
	}
	GameManager.show_tooltip.emit(unit_data, current_stats, active_buffs, global_position)

func _on_mouse_exited_control():
	GameManager.hide_tooltip.emit()

# Deprecated Area2D logic kept if needed, but Control blocks it
func _on_area_2d_mouse_entered():
	_on_mouse_entered_control()

func _on_area_2d_mouse_exited():
	_on_mouse_exited_control()

func return_to_start():
	# Visual reset if needed
	pass

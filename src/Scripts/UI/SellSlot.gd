extends Panel

func _init():
	custom_minimum_size = Vector2(80, 80)
	var lbl = Label.new()
	lbl.text = "SELL"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.anchors_preset = 15
	add_child(lbl)
	name = "SellSlot"

func _can_drop_data(_at_position, data):
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "grid_unit":
		return true
	return false

func _drop_data(_at_position, data):
	var unit = data.unit
	var cost = unit.unit_data.cost

	# Refund
	GameManager.add_resource("gold", cost)

	# Clear grid
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y
	GameManager.grid_manager._clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)

	unit.queue_free()

	# Recalculate buffs
	# Using call_deferred to ensure queue_free is processed or just safe call
	GameManager.grid_manager.recalculate_buffs()

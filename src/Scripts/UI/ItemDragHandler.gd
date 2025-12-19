extends Control

var slot_index: int = -1
var item_data: Dictionary = {}

func setup(index: int, data: Dictionary):
	slot_index = index
	item_data = data
	# Ensure this control captures input
	mouse_filter = MOUSE_FILTER_PASS

func _get_drag_data(at_position):
	if slot_index == -1 or item_data.is_empty():
		return null

	var preview = TextureRect.new()
	var item_id = item_data.get("item_id")
	if item_id:
		var icon = AssetLoader.get_item_icon(item_id)
		if icon:
			preview.texture = icon

	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(40, 40)
	preview.modulate.a = 0.7

	# Center the preview on mouse
	var c = Control.new()
	c.add_child(preview)
	preview.position = -preview.size / 2
	set_drag_preview(c)

	return {
		"source": "inventory",
		"item": item_data,
		"slot_index": slot_index
	}

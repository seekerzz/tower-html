extends Control

var slot_index: int = -1
var item_data: Dictionary = {}

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if !item_data.is_empty():
				GameManager.use_item(item_data)

func _get_drag_data(at_position):
	if item_data.is_empty():
		return null

	# Create drag preview
	var preview = TextureRect.new()
	var item_id = item_data.get("item_id", "")
	var icon = AssetLoader.get_item_icon(item_id)

	if icon:
		preview.texture = icon
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.size = Vector2(40, 40)
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

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

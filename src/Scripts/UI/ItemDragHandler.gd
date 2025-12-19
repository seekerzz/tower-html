extends Control

var slot_index: int = -1
var item_data: Dictionary = {}

func setup(index: int, data: Dictionary):
	slot_index = index
	item_data = data

func _get_drag_data(at_position):
	if item_data.is_empty():
		return null

	# Create Preview
	var preview = TextureRect.new()
	var icon_texture = null

	# Try to get texture from children first (WYSIWYG)
	for child in get_children():
		if child is TextureRect and child.texture:
			icon_texture = child.texture
			break

	# Fallback to AssetLoader if no child texture found
	if !icon_texture:
		var item_id = item_data.get("item_id")
		icon_texture = AssetLoader.get_item_icon(item_id)

	if icon_texture:
		preview.texture = icon_texture
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.size = Vector2(40, 40)
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		set_drag_preview(preview)

	return {
		"source": "inventory",
		"item": item_data,
		"slot_index": slot_index
	}

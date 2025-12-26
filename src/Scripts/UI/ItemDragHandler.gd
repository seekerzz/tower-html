extends Control

var slot_index: int = -1
var item_data: Dictionary = {}

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if !item_data.is_empty():
			var item_id = item_data.get("item_id", "")
			if item_id != "":
				# Right click logic: Use item
				# If target_unit required, we might need more logic,
				# but for now, Holy Sword targets nearest or self, or debug usage.
				# Actually, the requirement says "Right click -> use".
				# For Holy Sword (target_unit), we need a target.
				# Simplified: If target_unit type, try to apply to a selected unit or find nearest friend?
				# Let's try to apply to the first unit we find for testing/simplicity or self if possible (but items are in UI).

				# Better: check if we can simply call use_item_effect with null, and let GameManager handle 'smart casting' or fail.
				# But GameManager.use_item_effect("holy_sword", target) requires target.

				var target = null
				var item_type = Constants.ITEM_TYPES.get(item_id, {}).get("type", "consumable")

				if item_type == "target_unit":
					# Find a target (e.g. random friendly unit)
					var units = get_tree().get_nodes_in_group("units") # Assuming units are in group 'units'?
					# Unit.gd does not seem to add itself to 'units' group explicitly in _ready?
					# Let's check Unit.gd. It doesn't.

					# Fallback: Ask GridManager
					if GameManager.grid_manager:
						for key in GameManager.grid_manager.tiles:
							var tile = GameManager.grid_manager.tiles[key]
							if tile.unit:
								target = tile.unit
								break

				if GameManager.use_item_effect(item_id, target):
					# Consume item
					if GameManager.inventory_manager:
						GameManager.inventory_manager.remove_item(slot_index)
				else:
					print("Item usage failed or no target found.")

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

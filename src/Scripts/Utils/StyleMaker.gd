class_name StyleMaker
extends RefCounted

static func get_flat_style(bg_color: Color, radius: int = UIConstants.CORNER_RADIUS.large, border: int = 0, border_color: Color = Color.WHITE) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(radius)
	style.border_width_bottom = border
	style.border_width_left = border
	style.border_width_right = border
	style.border_width_top = border
	style.border_color = border_color
	return style

static func get_slot_style() -> StyleBoxFlat:
	return get_flat_style(UIConstants.COLORS.slot_bg, UIConstants.CORNER_RADIUS.large)

static func get_button_style(color_type: String) -> StyleBoxFlat:
	var color = UIConstants.COLORS.get(color_type, UIConstants.COLORS.primary)
	return get_flat_style(color, UIConstants.CORNER_RADIUS.large)

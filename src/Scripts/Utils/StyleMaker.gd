class_name StyleMaker
extends RefCounted

static func get_flat_style(bg_color: Color, radius: int = 4, border: int = 0, border_color: Color = Color.WHITE) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(radius)
	style.border_width_bottom = border
	style.border_width_left = border
	style.border_width_right = border
	style.border_width_top = border
	style.border_color = border_color
	return style

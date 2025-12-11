class_name ShopCard
extends PanelContainer

signal card_clicked(unit_key)

var unit_key: String
var base_style: StyleBoxFlat
var active_tween: Tween

# UI Components
var icon_label: Label
var name_label: Label
var price_label: Label
var content_container: VBoxContainer

func _init():
	# 1. Setup Base Style
	base_style = StyleMaker.get_flat_style(Color("#2c3e50"), 8)
	add_theme_stylebox_override("panel", base_style)

	# 2. Setup Layout
	content_container = VBoxContainer.new()
	content_container.alignment = BoxContainer.ALIGNMENT_CENTER
	content_container.add_theme_constant_override("separation", 4)
	add_child(content_container)

	# 3. Icon (Using Label for emoji as placeholder)
	icon_label = Label.new()
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 32)
	content_container.add_child(icon_label)

	# 4. Name
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(name_label)

	# 5. Price
	price_label = Label.new()
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_color_override("font_color", Color.GOLD)
	content_container.add_child(price_label)

	# 6. Interaction
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _ready():
	pass

func setup(key: String):
	unit_key = key
	var proto = Constants.UNIT_TYPES[unit_key]

	icon_label.text = proto.icon
	name_label.text = proto.name
	price_label.text = "%d💰" % proto.cost

	# Tooltip handled by Shop.gd via GameManager signals

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(unit_key)
		accept_event()

func _on_mouse_entered():
	if active_tween: active_tween.kill()
	active_tween = create_tween().set_parallel(true)

	# Lighten background
	active_tween.tween_property(base_style, "bg_color", Color("#2c3e50").lightened(0.2), 0.1)

	# Move Background Visual Up 2px using expand margins
	# Top expands up (positive), Bottom shrinks up (negative)
	active_tween.tween_property(base_style, "expand_margin_top", 2.0, 0.1)
	active_tween.tween_property(base_style, "expand_margin_bottom", -2.0, 0.1)

func _on_mouse_exited():
	if active_tween: active_tween.kill()
	active_tween = create_tween().set_parallel(true)

	# Restore background color
	active_tween.tween_property(base_style, "bg_color", Color("#2c3e50"), 0.1)

	# Restore margins
	active_tween.tween_property(base_style, "expand_margin_top", 0.0, 0.1)
	active_tween.tween_property(base_style, "expand_margin_bottom", 0.0, 0.1)

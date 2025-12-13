extends PanelContainer

const MATERIAL_KEYS = ["mucus", "poison", "fang", "wood", "snow", "stone"]

@onready var container = $VBoxContainer
@onready var header_container = $VBoxContainer/HeaderContainer
@onready var toggle_btn = $VBoxContainer/HeaderContainer/ToggleButton

var buttons: Dictionary = {} # mat_key -> Button
var is_collapsed: bool = false
var panel_tween: Tween

func _ready():
	# container already exists from tscn
	toggle_btn.pressed.connect(_on_toggle_pressed)

	# Create buttons
	for mat_key in MATERIAL_KEYS:
		var btn = Button.new()
		btn.toggle_mode = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.connect("pressed", func(): _on_material_clicked(mat_key))

		# Set custom minimum size for better clickability
		btn.custom_minimum_size = Vector2(100, 40)

		container.add_child(btn)
		buttons[mat_key] = btn

	# Connect to GameManager
	if GameManager.has_signal("resource_changed"):
		GameManager.resource_changed.connect(_update_ui)

	_update_ui()

func _on_toggle_pressed():
	is_collapsed = !is_collapsed
	_animate_panel()

func _animate_panel():
	if panel_tween and panel_tween.is_valid():
		panel_tween.kill()
	panel_tween = create_tween()

	var target_x: float
	if is_collapsed:
		toggle_btn.text = "▶"
		# Collapse to left.
		# If we move to x = -width, it's hidden.
		# We want the button to be visible.
		# The button is inside the panel.
		# We can just move the panel offscreen.
		# But the button needs to stick out?
		# Or we use a negative margin?

		# Current structure: PanelContainer -> VBox -> Header(Label+Button)
		# Button is on the right of header.
		# If we want panel to go Left, but keep button visible on Right edge of panel.
		# And panel is at Left of screen.

		# If we move panel to -Width + ButtonWidth?
		var width = size.x
		var btn_width = toggle_btn.size.x
		target_x = -width + btn_width + 10 # +10 margin
	else:
		toggle_btn.text = "◀"
		target_x = 20 # Original offset

	panel_tween.tween_property(self, "position:x", target_x, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_material_clicked(selected_key: String):
	var draw_manager = _get_draw_manager()
	if not draw_manager:
		push_warning("DrawManager not found!")
		return

	var current = draw_manager.current_material

	if current == selected_key:
		# Deselect if clicking same
		draw_manager.current_material = ""
		# Also unpress the button visually if needed, though toggle_mode handles some
	else:
		# Select new
		draw_manager.select_material(selected_key)

	_update_ui()

func _update_ui():
	var draw_manager = _get_draw_manager()
	var current_mat = ""
	if draw_manager:
		current_mat = draw_manager.current_material

	for mat_key in buttons:
		var btn = buttons[mat_key]
		var count = GameManager.materials.get(mat_key, 0)
		var mat_info = Constants.MATERIAL_TYPES.get(mat_key, {})
		var icon = mat_info.get("icon", "?")
		var mat_name = mat_info.get("name", mat_key)

		# Update Text: Icon Name (Count)
		btn.text = "%s %s (%d)" % [icon, mat_name, count]

		# Update Highlight
		btn.set_pressed_no_signal(mat_key == current_mat)

func _get_draw_manager():
	# If running in a test or game where MainGame is root
	var root = get_tree().current_scene
	if root.has_node("DrawManager"):
		return root.get_node("DrawManager")

	# If running in production where MainGame might be a child of something else or specific hierarchy
	# MainGUI is usually in CanvasLayer in MainGame
	# So self -> Panel -> ... -> MainGUI -> CanvasLayer -> MainGame
	# Try searching up and then down
	var main_game = _find_main_game(self)
	if main_game and main_game.has_node("DrawManager"):
		return main_game.get_node("DrawManager")

	return null

func _find_main_game(node):
	var current = node
	while current:
		if current.name == "MainGame" or current.has_node("DrawManager"):
			return current
		current = current.get_parent()
	return null

extends PanelContainer

const MATERIAL_KEYS = ["mucus", "poison", "fang", "wood", "snow", "stone"]

# Main layout
var main_hbox: HBoxContainer
var toggle_button: Button
var content_wrapper: Control # Wrapper to clip content
var material_container: VBoxContainer

var is_expanded: bool = true
var panel_tween: Tween
var content_width: float = 120.0 # Approximate width of buttons + margins

var buttons: Dictionary = {} # mat_key -> Button

func _ready():
	# Clean up existing children if any (from scene)
	for child in get_children():
		child.queue_free()

	# Create Main Layout (Horizontal)
	main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 0) # No gap between toggle and content
	add_child(main_hbox)

	# 1. Toggle Button (Left side of the panel, so it remains visible when collapsed right)
	toggle_button = Button.new()
	toggle_button.text = "🏗️" # Or ">"
	toggle_button.toggle_mode = false # We handle state manually or use it for visual
	toggle_button.focus_mode = Control.FOCUS_NONE
	toggle_button.custom_minimum_size = Vector2(30, 40) # Thin vertical strip or small square?
	# Let's make it span the height or just be a handle?
	# A handle is usually better. Let's start with a small button.
	# Actually, if the panel is centered vertically on the right, the button should probably be vertically centered too.
	toggle_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	toggle_button.pressed.connect(_on_toggle_pressed)
	main_hbox.add_child(toggle_button)

	# 2. Content Wrapper (to clip the sliding content)
	# Use Control to avoid child min_size forcing parent size (like Containers do)
	content_wrapper = Control.new()
	content_wrapper.clip_contents = true
	content_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Allow it to take space
	content_wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_wrapper.custom_minimum_size.x = content_width # Start expanded

	main_hbox.add_child(content_wrapper)

	# 3. Material Container (The actual buttons)
	material_container = VBoxContainer.new()
	# Do NOT set size_flags to expand, as we want fixed size inside the clipping control
	# material_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	material_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Set fixed size for the content so it doesn't shrink when wrapper shrinks
	material_container.custom_minimum_size.x = content_width
	material_container.size.x = content_width # Explicitly set size

	# We need to manually manage the height if we want it to fill vertical
	# Or use anchors. Since parent is Control, we can use anchors.
	# Anchor Top/Bottom/Left, but keep Width fixed?
	# PRESET_LEFT_WIDE anchors to Left, Top, Bottom. Width is determined by size/min_size.
	material_container.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	# Reset offset_right to match width (otherwise anchor logic might stretch it?)
	# PRESET_LEFT_WIDE usually sets right anchor to 0 (Left).
	# So we just need to ensure width is correct.
	material_container.custom_minimum_size.x = content_width

	content_wrapper.add_child(material_container)

	# Create buttons inside material_container
	for mat_key in MATERIAL_KEYS:
		var btn = Button.new()
		btn.toggle_mode = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.connect("pressed", func(): _on_material_clicked(mat_key))

		# Set custom minimum size for better clickability
		btn.custom_minimum_size = Vector2(100, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Fill the container width

		material_container.add_child(btn)
		buttons[mat_key] = btn

	# Connect to GameManager
	if GameManager.has_signal("resource_changed"):
		GameManager.resource_changed.connect(_update_ui)

	_update_ui()

	# Initial state check? Default is expanded.

func _on_toggle_pressed():
	is_expanded = not is_expanded
	_animate_panel()

func _animate_panel():
	if panel_tween and panel_tween.is_valid():
		panel_tween.kill()

	panel_tween = create_tween()

	var target_width = content_width if is_expanded else 0.0
	var duration = 0.3

	# Animate the wrapper's minimum width.
	# Because MainGUI uses anchors with Grow Direction Left, shrinking this wrapper
	# will cause the whole BuildPanel to shrink towards the Right edge.
	panel_tween.tween_property(content_wrapper, "custom_minimum_size:x", target_width, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Optional: Rotate arrow or change icon
	# toggle_button.text = ">>" if is_expanded else "<<" # Or something similar

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

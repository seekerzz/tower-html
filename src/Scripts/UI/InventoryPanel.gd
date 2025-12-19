extends Control

# Constants
const SLOT_SIZE = Vector2(60, 60)
const COLUMNS = 4
const TOTAL_SLOTS = 8

# Child nodes
var grid_container: GridContainer

func _ready():
    # Setup UI structure if not already set via editor
    _setup_ui()

    # Connect signals
    # Assuming GameManager.inventory_manager exists as per instructions
    if GameManager.get("inventory_manager"):
        if GameManager.inventory_manager.has_signal("inventory_updated"):
            GameManager.inventory_manager.inventory_updated.connect(_on_inventory_updated)
            # Initial update if data exists
            if GameManager.inventory_manager.get("inventory"):
                _on_inventory_updated(GameManager.inventory_manager.inventory)

func _setup_ui():
    # Check if we have a PanelContainer/GridContainer hierarchy, if not create it
    # But usually .tscn defines structure. We will ensure the GridContainer exists.
    var panel_container = get_node_or_null("PanelContainer")
    if not panel_container:
        panel_container = PanelContainer.new()
        panel_container.name = "PanelContainer"
        panel_container.layout_mode = 1
        panel_container.anchors_preset = 15 # Full rect
        add_child(panel_container)

        # Style for PanelContainer (optional, or transparent)
        var style = StyleBoxEmpty.new()
        panel_container.add_theme_stylebox_override("panel", style)

    grid_container = panel_container.get_node_or_null("GridContainer")
    if not grid_container:
        grid_container = GridContainer.new()
        grid_container.name = "GridContainer"
        grid_container.columns = COLUMNS
        grid_container.add_theme_constant_override("h_separation", 10)
        grid_container.add_theme_constant_override("v_separation", 10)
        panel_container.add_child(grid_container)

    # Initialize empty slots
    _create_slots([])

func _create_slots(items: Array):
    # Clear existing
    for child in grid_container.get_children():
        child.queue_free()

    for i in range(TOTAL_SLOTS):
        var slot = Control.new()
        slot.custom_minimum_size = SLOT_SIZE
        slot.name = "Slot_%d" % i

        # Background
        var bg = Panel.new()
        bg.layout_mode = 1
        bg.anchors_preset = 15
        bg.mouse_filter = MOUSE_FILTER_IGNORE

        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.2, 0.2, 0.2, 1)
        style.set_corner_radius_all(8)
        bg.add_theme_stylebox_override("panel", style)

        slot.add_child(bg)

        # Item Data
        if i < items.size() and items[i] != null:
            var item_data = items[i]
            _add_item_to_slot(slot, item_data)

        grid_container.add_child(slot)

func _add_item_to_slot(slot: Control, item_data):
    # item_data is expected to be a dictionary or object with:
    # key (string): for icon lookup
    # count (int): amount

    var icon_key = item_data.get("key", "")
    var count = item_data.get("count", 1)

    if icon_key == "": return

    var icon_tex = AssetLoader.get_item_icon(icon_key)
    if icon_tex:
        var icon_rect = TextureRect.new()
        icon_rect.texture = icon_tex
        icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon_rect.layout_mode = 1
        icon_rect.anchors_preset = 15
        # Margin
        icon_rect.offset_left = 5
        icon_rect.offset_top = 5
        icon_rect.offset_right = -5
        icon_rect.offset_bottom = -5

        slot.add_child(icon_rect)

    if count > 1:
        var label = Label.new()
        label.text = str(count)
        label.layout_mode = 1
        label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
        label.offset_right = -5
        label.offset_bottom = -2
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        slot.add_child(label)

func _on_inventory_updated(new_inventory):
    _create_slots(new_inventory)

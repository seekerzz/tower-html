extends Control

class_name BattleUI

const CORE_TYPES = {
    "cornucopia": {
        "name": "丰饶之角",
        "icon": "🌽",
        "desc": "基础食物产出 +100%",
        "bonus": {"food_rate": 5.0}
    },
    "thunder": {
        "name": "雷霆尖塔",
        "icon": "⚡",
        "desc": "核心每秒发射闪电攻击最近敌人。",
        "bonus": {"mana_rate": 1.0}
    },
    "alchemy": {
        "name": "炼金熔炉",
        "icon": "⚗️",
        "desc": "每秒产出 +2 法力。",
        "bonus": {"mana_rate": 2.0}
    },
    "war": {
        "name": "战争图腾",
        "icon": "⚔️",
        "desc": "所有友军单位伤害 +50%。",
        "bonus": {"damage": 0.5}
    }
}

const UNIT_TYPES = {
    "mouse": {"name": "加特林鼠", "icon": "🐭", "cost": 15, "desc": "超快攻速"},
    "turtle": {"name": "狙击龟", "icon": "🐢", "cost": 25, "desc": "超远单发"},
    "ninja": {"name": "忍者", "icon": "🥷", "cost": 40, "desc": "穿透投掷"},
    "wizard": {"name": "大法师", "icon": "🧙‍♂️", "cost": 50, "desc": "高爆发"},
    "tesla": {"name": "磁暴线圈", "icon": "⚡", "cost": 70, "desc": "链式闪电"}
}

var grid_buttons: Array[Button] = []
var bench_buttons: Array[Button] = []
var shop_buttons: Array[Button] = []
var core_label: Label
var hp_bar: ProgressBar
var food_bar: ProgressBar
var mana_bar: ProgressBar
var wave_label: Label
var wave_status: Label
var enemy_label: Label
var gold_label: Label
var timeline: HBoxContainer
var selection_layer: Control
var skill_bar: VBoxContainer
var shop_panel: Control
var start_wave_button: Button

var grid_state := {}
var bench_state: Array = []

var selected_core := ""
var holding_unit: Dictionary = {}

var wave := 1
var gold := 60
var food := 100.0
var mana := 50.0
var hp := 100.0
var max_hp := 100.0
var max_food := 200.0
var max_mana := 100.0
var in_wave := false
var enemies_left := 0
var enemy_timer := Timer.new()

func _ready() -> void:
    anchor_left = 0
    anchor_top = 0
    anchor_right = 1
    anchor_bottom = 1
    mouse_filter = Control.MOUSE_FILTER_PASS

    _build_background()
    _build_selection()
    _build_ui()
    _build_shop()
    _reset_bench()

    add_child(enemy_timer)
    enemy_timer.timeout.connect(_on_enemy_tick)

    _update_timeline()
    _update_top_hud()

func _build_background() -> void:
    var bg := ColorRect.new()
    bg.color = Color("1a1a2e")
    bg.anchor_right = 1
    bg.anchor_bottom = 1
    add_child(bg)

    var grid := ColorRect.new()
    grid.anchor_right = 1
    grid.anchor_bottom = 1
    var shader := Shader.new()
    shader.code = """
        shader_type canvas_item;
        uniform float spacing = 20.0;
        uniform vec4 line_color : source_color = vec4(0.16, 0.18, 0.26, 0.6);
        void fragment(){
            vec2 uv = FRAGCOORD.xy / spacing;
            float line = step(0.98, fract(uv.x)) + step(0.98, fract(uv.y));
            float alpha = clamp(line, 0.0, 1.0);
            COLOR = vec4(line_color.rgb, alpha * line_color.a);
        }
    """
    var mat := ShaderMaterial.new()
    mat.shader = shader
    grid.material = mat
    add_child(grid)

func _build_selection() -> void:
    selection_layer = Control.new()
    selection_layer.anchor_right = 1
    selection_layer.anchor_bottom = 1

    var panel := VBoxContainer.new()
    panel.anchor_left = 0.5
    panel.anchor_top = 0.5
    panel.anchor_right = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -280
    panel.offset_top = -180
    panel.offset_right = 280
    panel.offset_bottom = 180
    panel.alignment = BoxContainer.ALIGNMENT_CENTER
    panel.add_theme_constant_override("separation", 12)

    var title := Label.new()
    title.text = "选择你的核心流派"
    title.autowrap_mode = TextServer.AUTOWRAP_WORD
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    panel.add_child(title)

    var grid_box := GridContainer.new()
    grid_box.columns = 2
    grid_box.custom_minimum_size = Vector2(520, 200)
    grid_box.add_theme_constant_override("h_separation", 12)
    grid_box.add_theme_constant_override("v_separation", 12)

    for core_id in CORE_TYPES.keys():
        var btn := Button.new()
        btn.text = "%s %s\n%s" % [CORE_TYPES[core_id]["icon"], CORE_TYPES[core_id]["name"], CORE_TYPES[core_id]["desc"]]
        btn.tooltip_text = CORE_TYPES[core_id]["desc"]
        btn.custom_minimum_size = Vector2(240, 90)
        btn.pressed.connect(_on_core_selected.bind(core_id))
        grid_box.add_child(btn)
    panel.add_child(grid_box)
    selection_layer.add_child(panel)
    add_child(selection_layer)

func _build_ui() -> void:
    # Top HUD
    var hud := HBoxContainer.new()
    hud.anchor_right = 1
    hud.offset_left = 16
    hud.offset_top = 12
    hud.offset_right = -16
    hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hud.add_theme_constant_override("separation", 12)
    add_child(hud)

    # Left block
    var left_panel := _create_panel(Vector2(220, 180))
    left_panel.name = "LeftPanel"
    hud.add_child(left_panel)

    var hp_row := _create_stat_row("❤️ 基地核心", "100/100")
    hp_bar = _create_bar(Color.RED, 100)
    hp_row["container"].add_child(hp_bar)
    left_panel.add_child(hp_row["container"])
    var build_title := Label.new()
    build_title.text = "流派: 未知"
    build_title.name = "CoreLabel"
    build_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    build_title.autowrap_mode = TextServer.AUTOWRAP_WORD
    left_panel.add_child(build_title)
    core_label = build_title

    var build_panel := _create_build_panel()
    left_panel.add_child(build_panel)

    var cheat := Button.new()
    cheat.text = "🛠️ 作弊模式"
    cheat.pressed.connect(_activate_cheat)
    left_panel.add_child(cheat)

    # Center block
    var center_panel := _create_panel(Vector2(320, 170))
    hud.add_child(center_panel)

    var wave_title := Label.new()
    wave_title.text = "WAVE 1"
    wave_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    wave_title.add_theme_font_size_override("font_size", 22)
    center_panel.add_child(wave_title)
    wave_label = wave_title

    var status_row := HBoxContainer.new()
    status_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    status_row.add_theme_constant_override("separation", 6)
    wave_status = Label.new()
    wave_status.text = "准备中"
    enemy_label = Label.new()
    enemy_label.text = ""
    status_row.add_child(wave_status)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    status_row.add_child(spacer)
    status_row.add_child(enemy_label)
    center_panel.add_child(status_row)

    var wave_bar := _create_bar(Color.DODGER_BLUE, 0)
    center_panel.add_child(wave_bar)

    timeline = HBoxContainer.new()
    timeline.alignment = BoxContainer.ALIGNMENT_CENTER
    timeline.add_theme_constant_override("separation", 4)
    center_panel.add_child(timeline)

    # Right block
    var right_panel := _create_panel(Vector2(220, 180))
    hud.add_child(right_panel)

    var food_row := _create_stat_row("⚡ 食物", "100/200")
    food_bar = _create_bar(Color.YELLOW, 50)
    food_row["container"].add_child(food_bar)
    right_panel.add_child(food_row["container"])

    var mana_row := _create_stat_row("💧 法力", "50/100")
    mana_bar = _create_bar(Color.SKY_BLUE, 50)
    mana_row["container"].add_child(mana_bar)
    right_panel.add_child(mana_row["container"])

    var income := Label.new()
    income.text = "产出: 10/s"
    right_panel.add_child(income)

    var gold_row := HBoxContainer.new()
    gold_row.alignment = BoxContainer.ALIGNMENT_END
    gold_row.add_child(Label.new())
    gold_label = Label.new()
    gold_label.text = "50"
    gold_row.add_child(Label.new())
    gold_row.add_child(gold_label)
    right_panel.add_child(gold_row)

    # Skill bar left
    var skill_layer := VBoxContainer.new()
    skill_layer.anchor_left = 0
    skill_layer.anchor_top = 0.5
    skill_layer.anchor_bottom = 0.5
    skill_layer.offset_left = 12
    skill_layer.offset_top = -120
    skill_layer.add_theme_constant_override("separation", 8)
    skill_bar = skill_layer
    add_child(skill_layer)

    # Grid layer
    var grid_root := Control.new()
    grid_root.anchor_left = 0.5
    grid_root.anchor_top = 0.5
    grid_root.anchor_right = 0.5
    grid_root.anchor_bottom = 0.5
    grid_root.offset_left = -210
    grid_root.offset_top = -160
    grid_root.size = Vector2(420, 320)
    add_child(grid_root)

    var grid_container := GridContainer.new()
    grid_container.columns = 3
    grid_container.anchor_left = 0.5
    grid_container.anchor_top = 0.5
    grid_container.anchor_right = 0.5
    grid_container.anchor_bottom = 0.5
    grid_container.offset_left = -180
    grid_container.offset_top = -140
    grid_container.custom_minimum_size = Vector2(360, 280)
    grid_container.add_theme_constant_override("h_separation", 10)
    grid_container.add_theme_constant_override("v_separation", 10)
    grid_root.add_child(grid_container)

    for i in range(9):
        var tile := Button.new()
        tile.custom_minimum_size = Vector2(110, 80)
        tile.text = "空地"
        tile.toggle_mode = true
        tile.button_pressed = false
        tile.add_theme_color_override("font_color", Color(0.85, 0.87, 0.9))
        tile.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
        tile.pressed.connect(_on_tile_pressed.bind(i))
        grid_buttons.append(tile)
        grid_container.add_child(tile)
        grid_state[i] = null

    # Bench & shop container handled separately

    start_wave_button = Button.new()
    start_wave_button.text = "⚔️ 开始战斗"
    start_wave_button.custom_minimum_size = Vector2(150, 36)
    start_wave_button.pressed.connect(_start_wave)

func _create_panel(min_size: Vector2) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = min_size
    panel.add_theme_stylebox_override("panel", _dark_style())
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    var vbox := VBoxContainer.new()
    vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_theme_constant_override("separation", 6)
    panel.add_child(vbox)
    return panel

func _dark_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.16, 0.17, 0.23, 0.95)
    style.border_color = Color(0.35, 0.38, 0.46)
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    style.corner_radius_bottom_left = 10
    style.corner_radius_bottom_right = 10
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    return style

func _create_stat_row(title: String, value: String) -> Dictionary:
    var container := VBoxContainer.new()
    container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var top := HBoxContainer.new()
    top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var name_label := Label.new()
    name_label.text = title
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var val := Label.new()
    val.text = value
    top.add_child(name_label)
    top.add_child(val)
    container.add_child(top)
    return {"container": container, "value_label": val}

func _create_bar(color: Color, percent: float) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.value = percent
    bar.max_value = 100
    bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bar.add_theme_color_override("fg_color", color)
    bar.add_theme_color_override("font_color", Color.WHITE)
    bar.show_percentage = false
    return bar

func _create_build_panel() -> GridContainer:
    var build := GridContainer.new()
    build.columns = 3
    build.add_theme_constant_override("h_separation", 4)
    build.add_theme_constant_override("v_separation", 4)
    var mats := {"木": Color(0.82, 0.52, 0.25), "石": Color(0.58, 0.63, 0.66), "雪": Color(0.45, 0.65, 0.95)}
    for name in mats.keys():
        var btn := Button.new()
        btn.text = "%s x10" % name
        btn.add_theme_color_override("font_color", mats[name])
        btn.tooltip_text = "建设材料"
        build.add_child(btn)
    return build

func _build_shop() -> void:
    shop_panel = PanelContainer.new()
    shop_panel.anchor_left = 0.5
    shop_panel.anchor_right = 0.5
    shop_panel.anchor_top = 1
    shop_panel.anchor_bottom = 1
    shop_panel.offset_left = -360
    shop_panel.offset_right = 360
    shop_panel.offset_bottom = -8
    shop_panel.custom_minimum_size = Vector2(720, 200)
    shop_panel.add_theme_stylebox_override("panel", _dark_style())
    add_child(shop_panel)

    var vbox := VBoxContainer.new()
    vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_theme_constant_override("separation", 8)
    shop_panel.add_child(vbox)

    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 8)
    var title := Label.new()
    title.text = "🛒 补给站"
    header.add_child(title)
    var header_spacer := Control.new()
    header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(header_spacer)
    var refresh := Button.new()
    refresh.text = "🔄 刷新(10💰)"
    refresh.pressed.connect(_refresh_shop)
    header.add_child(refresh)
    vbox.add_child(header)

    var bench_row := HBoxContainer.new()
    bench_row.add_theme_constant_override("separation", 8)
    var bench_label := Label.new()
    bench_label.text = "暂存区"
    bench_row.add_child(bench_label)
    var bench_box := HBoxContainer.new()
    bench_box.add_theme_constant_override("separation", 6)
    bench_row.add_child(bench_box)
    for i in range(5):
        var slot := Button.new()
        slot.custom_minimum_size = Vector2(70, 60)
        slot.text = "空"
        slot.pressed.connect(_on_bench_pressed.bind(i))
        bench_buttons.append(slot)
        bench_box.add_child(slot)
    var sell := Button.new()
    sell.text = "出售"
    sell.tooltip_text = "出售选中单位 +50%成本"
    sell.pressed.connect(_sell_unit)
    bench_row.add_child(sell)
    vbox.add_child(bench_row)

    var shop_row := HBoxContainer.new()
    shop_row.add_theme_constant_override("separation", 8)
    vbox.add_child(shop_row)

    for i in range(4):
        var card := Button.new()
        card.custom_minimum_size = Vector2(150, 100)
        card.text = "空卡片"
        card.pressed.connect(_on_shop_pressed.bind(i))
        shop_buttons.append(card)
        shop_row.add_child(card)

    vbox.add_child(start_wave_button)

    _roll_shop()

func _reset_bench() -> void:
    bench_state.resize(5)
    for i in range(5):
        bench_state[i] = null

func _on_core_selected(core_id: String) -> void:
    selected_core = core_id
    selection_layer.visible = false
    core_label.text = "流派: %s" % CORE_TYPES[core_id]["name"]
    _build_skills_for_core()

func _build_skills_for_core() -> void:
    _clear_children(skill_bar)
    for i in range(3):
        var btn := Button.new()
        btn.text = "%s 技能 %d" % [CORE_TYPES[selected_core]["icon"], i+1]
        btn.tooltip_text = CORE_TYPES[selected_core]["desc"]
        btn.custom_minimum_size = Vector2(120, 36)
        btn.disabled = selected_core == "" 
        skill_bar.add_child(btn)

func _on_shop_pressed(index: int) -> void:
    if in_wave:
        return
    var data = shop_buttons[index].get_meta("unit_id")
    if data == null:
        return
    var unit_id: String = data
    var cfg = UNIT_TYPES[unit_id]
    var cost: int = cfg["cost"]
    if gold < cost:
        _flash_label(gold_label)
        return
    var bench_slot := bench_state.find(null)
    if bench_slot == -1:
        _flash_label(bench_buttons[0])
        return
    gold -= cost
    bench_state[bench_slot] = {
        "id": unit_id,
        "name": cfg["name"],
        "icon": cfg["icon"],
        "cost": cost
    }
    _update_shop_display()
    _update_bench_display()
    _update_top_hud()

func _on_bench_pressed(index: int) -> void:
    var unit = bench_state[index]
    if holding_unit.is_empty() and unit != null:
        holding_unit = unit.duplicate()
        bench_state[index] = null
    elif not holding_unit.is_empty() and unit == null:
        bench_state[index] = holding_unit
        holding_unit = {}
    else:
        return
    _update_bench_display()
    _update_top_hud()

func _on_tile_pressed(index: int) -> void:
    if holding_unit.is_empty():
        if grid_state[index] != null:
            holding_unit = grid_state[index]
            grid_state[index] = null
    else:
        grid_state[index] = holding_unit
        holding_unit = {}
    _update_grid_display()
    _update_top_hud()

func _sell_unit() -> void:
    if holding_unit.is_empty():
        return
    gold += int(holding_unit.get("cost", 0) * 0.5)
    holding_unit.clear()
    _update_bench_display()
    _update_top_hud()

func _refresh_shop() -> void:
    if gold < 10 or in_wave:
        return
    gold -= 10
    _roll_shop()
    _update_top_hud()

func _roll_shop() -> void:
    var ids: Array = UNIT_TYPES.keys()
    ids.shuffle()
    for i in range(shop_buttons.size()):
        var id: String = str(ids[i % ids.size()])
        var cfg: Dictionary = UNIT_TYPES[id]
        shop_buttons[i].text = "%s %s\n花费: %d" % [cfg["icon"], cfg["name"], cfg["cost"]]
        shop_buttons[i].set_meta("unit_id", id)
    _update_shop_display()

func _update_shop_display() -> void:
    for i in range(shop_buttons.size()):
        var data = shop_buttons[i].get_meta("unit_id")
        if data == null:
            continue
        var cfg: Dictionary = UNIT_TYPES[data]
        shop_buttons[i].text = "%s %s\n花费: %d" % [cfg["icon"], cfg["name"], cfg["cost"]]

func _update_bench_display() -> void:
    for i in range(bench_buttons.size()):
        var slot_btn := bench_buttons[i]
        var unit = bench_state[i]
        if unit == null:
            slot_btn.text = "空"
        else:
            slot_btn.text = "%s\n%s" % [unit["icon"], unit["name"]]

func _update_grid_display() -> void:
    for i in range(grid_buttons.size()):
        var tile := grid_buttons[i]
        var unit = grid_state[i]
        if unit == null:
            tile.text = "空地"
            tile.button_pressed = false
        else:
            tile.text = "%s\n%s" % [unit["icon"], unit["name"]]
            tile.button_pressed = true

func _update_timeline() -> void:
    _clear_children(timeline)
    for i in range(6):
        var badge := PanelContainer.new()
        badge.add_theme_stylebox_override("panel", _dark_style())
        badge.custom_minimum_size = Vector2(36, 36)
        var lab := Label.new()
        lab.text = str(wave + i)
        lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        badge.add_child(lab)
        timeline.add_child(badge)

func _update_top_hud() -> void:
    hp_bar.value = hp / max_hp * 100.0
    food_bar.value = food / max_food * 100.0
    mana_bar.value = mana / max_mana * 100.0
    wave_label.text = "WAVE %d" % wave
    gold_label.text = str(gold)
    if enemies_left > 0:
        enemy_label.text = "敌人: %d" % enemies_left
    else:
        enemy_label.text = ""
    if not holding_unit.is_empty():
        wave_status.text = "手牌: %s" % holding_unit.get("name", "")
    elif in_wave:
        wave_status.text = "战斗中"
    else:
        wave_status.text = "准备中"

func _start_wave() -> void:
    if in_wave:
        return
    in_wave = true
    enemies_left = 6 + wave * 2
    enemy_timer.wait_time = 0.8
    enemy_timer.start()
    _update_top_hud()

func _on_enemy_tick() -> void:
    if enemies_left <= 0:
        enemy_timer.stop()
        in_wave = false
        _end_wave()
        return
    enemies_left -= 1
    _update_top_hud()

func _end_wave() -> void:
    gold += 12 + wave * 2
    food = clamp(food + 12, 0, max_food)
    mana = clamp(mana + 8, 0, max_mana)
    wave += 1
    _update_timeline()
    _update_top_hud()

func _activate_cheat() -> void:
    gold += 999
    food = max_food
    mana = max_mana
    _update_top_hud()

func _flash_label(node: Control) -> void:
    var tween := create_tween()
    tween.tween_property(node, "modulate", Color(1, 0.5, 0.5), 0.1)
    tween.tween_property(node, "modulate", Color(1, 1, 1), 0.2)

func _clear_children(node: Node) -> void:
    if node == null:
        return
    for child in node.get_children():
        child.queue_free()


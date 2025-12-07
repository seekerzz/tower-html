extends Control
class_name Main

# Quick port of ref.html gameplay into Godot.

const TILE_SIZE := 60
const BENCH_SIZE := 5
const COLORS := {
    "bg": Color("#1a1a2e"),
    "grid": Color("#303045"),
    "enemy": Color("#e74c3c"),
    "projectile": Color("#f1c40f"),
    "enemyProjectile": Color("#e91e63")
}

const CORE_TYPES := {
    "cornucopia": {"name":"丰饶之角","icon":"🌽","desc":"基础食物产出 +100%。\n平稳发育，适合新手。","bonus":{"foodRate":5}},
    "thunder": {"name":"雷霆尖塔","icon":"⚡","desc":"核心每秒发射闪电攻击最近敌人。\n伤害: 20 (随波次成长)","ability":"attack"},
    "alchemy": {"name":"炼金熔炉","icon":"⚗️","desc":"每秒产出 +2 法力。\n每波结束获得 10% 现有金币利息。","bonus":{"manaRate":2}},
    "war": {"name":"战争图腾","icon":"⚔️","desc":"食物产出减半。\n所有友军单位伤害 +50%。","bonus":{"foodRate":-2.5,"globalDmg":0.5}}
}

const MATERIAL_TYPES := {
    "mucus": {"name":"粘液","icon":"💧","color":Color("#00cec9"),"desc":"减速陷阱"},
    "poison": {"name":"毒药","icon":"🧪","color":Color("#2ecc71"),"desc":"毒雾屏障"},
    "fang": {"name":"尖牙","icon":"🦷","color":Color("#e74c3c"),"desc":"尖刺陷阱"},
    "wood": {"name":"木头","icon":"🪵","color":Color("#d35400"),"desc":"木栅栏"},
    "snow": {"name":"雪团","icon":"❄️","color":Color("#74b9ff"),"desc":"冰墙"},
    "stone": {"name":"石头","icon":"🪨","color":Color("#95a5a6"),"desc":"石墙"}
}

const BARRICADE_TYPES := {
    "mucus": {"hp":50,"type":"slow","strength":0.3,"color":Color(0,0.81,0.79,0.5),"width":8,"name":"粘液网"},
    "poison": {"hp":1,"type":"poison","strength":20,"color":Color(0.18,0.8,0.44,0.4),"width":20,"name":"毒雾","immune":true},
    "fang": {"hp":80,"type":"reflect","strength":10,"color":Color(0.91,0.3,0.24,0.8),"width":6,"name":"荆棘"},
    "wood": {"hp":200,"type":"block","strength":0,"color":Color("#d35400"),"width":6,"name":"木栏"},
    "snow": {"hp":150,"type":"freeze","strength":1.5,"color":Color("#74b9ff"),"width":8,"name":"冰墙"},
    "stone": {"hp":600,"type":"block","strength":0,"color":Color("#7f8c8d"),"width":10,"name":"石墙"}
}

const UNIT_TYPES := {
    "mouse": {"name":"加特林鼠","icon":"🐭","cost":15,"size":[1,1],"damage":3,"range":250,"atkSpeed":0.15,"foodCost":1.5,"manaCost":0,"attackType":"ranged","proj":"dot","desc":"远程:超快攻速"},
    "turtle": {"name":"狙击龟","icon":"🐢","cost":25,"size":[1,1],"damage":45,"range":500,"atkSpeed":1.8,"foodCost":8,"manaCost":0,"attackType":"ranged","proj":"rocket","desc":"远程:超远单发"},
    "ranger": {"name":"游侠","icon":"🤠","cost":60,"size":[1,1],"damage":12,"range":180,"atkSpeed":1.5,"foodCost":3,"manaCost":0,"attackType":"ranged","proj":"pellet","projCount":5,"spread":0.5,"desc":"霰弹:扇形5发"},
    "ninja": {"name":"忍者","icon":"🥷","cost":80,"size":[1,1],"damage":25,"range":250,"atkSpeed":0.8,"foodCost":4,"manaCost":0,"attackType":"ranged","proj":"shuriken","pierce":3,"desc":"直线穿透3敌"},
    "tesla": {"name":"磁暴线圈","icon":"⚡","cost":70,"size":[1,1],"damage":35,"range":200,"atkSpeed":1.2,"foodCost":5,"manaCost":5,"attackType":"ranged","proj":"lightning","chain":4,"desc":"攻击产生闪电链"},
    "cannon": {"name":"震荡炮","icon":"💣","cost":90,"size":[1,1],"damage":40,"range":200,"atkSpeed":2.0,"foodCost":8,"manaCost":0,"attackType":"ranged","proj":"swarm_wave","desc":"发射腐臭蜂群"},
    "void": {"name":"奇点","icon":"🌌","cost":200,"size":[1,1],"damage":5,"range":300,"atkSpeed":3.0,"foodCost":15,"manaCost":20,"attackType":"ranged","proj":"blackhole","desc":"发射黑洞(停留吸引)"},
    "knight": {"name":"狂战士","icon":"🗡️","cost":30,"size":[1,1],"damage":20,"range":100,"atkSpeed":0.8,"foodCost":4,"manaCost":0,"attackType":"melee","splash":60,"skill":"rage","skillCd":10,"desc":"近战:范围挥砍\n技能:血怒(30💧)"},
    "bear": {"name":"暴怒熊","icon":"🐻","cost":65,"size":[1,1],"damage":35,"range":80,"atkSpeed":1.2,"foodCost":5,"manaCost":0,"attackType":"melee","skill":"stun","skillCd":15,"desc":"近战:重击晕眩\n技能:震慑(30💧)"},
    "treant": {"name":"树人守卫","icon":"🌳","cost":40,"size":[1,1],"damage":10,"range":80,"atkSpeed":1.5,"foodCost":2,"manaCost":0,"attackType":"melee","desc":"肉盾:高血量"},
    "wizard": {"name":"大法师","icon":"🧙‍♂️","cost":50,"size":[1,1],"damage":60,"range":350,"atkSpeed":1.2,"foodCost":1,"manaCost":5,"attackType":"ranged","proj":"orb","splash":30,"skill":"nova","skillCd":12,"desc":"消耗法力高伤\n技能:新星(30💧)"},
    "phoenix": {"name":"凤凰","icon":"🦅","cost":150,"size":[1,1],"damage":25,"range":300,"atkSpeed":0.6,"foodCost":10,"manaCost":0,"attackType":"ranged","proj":"fire","splash":40,"skill":"firestorm","skillCd":20,"desc":"远程:AOE轰炸\n技能:火雨(30💧)"},
    "hydra": {"name":"三头犬","icon":"🐕","cost":120,"size":[2,2],"damage":40,"range":120,"atkSpeed":0.8,"foodCost":20,"manaCost":0,"attackType":"melee","skill":"devour_aura","desc":"2x2巨兽"},
    "plant": {"name":"向日葵","icon":"🌻","cost":20,"size":[1,1],"damage":0,"range":0,"atkSpeed":1.0,"foodCost":-6,"manaCost":0,"attackType":"none","produce":"food","produceAmt":6,"desc":"产出:食物+6/s"},
    "crystal": {"name":"法力水晶","icon":"💎","cost":30,"size":[1,1],"damage":0,"range":0,"atkSpeed":1.0,"foodCost":0,"manaCost":-3,"attackType":"none","produce":"mana","produceAmt":3,"desc":"产出:法力+3/s"},
    "torch": {"name":"红莲火炬","icon":"🔥","cost":35,"size":[1,1],"damage":0,"range":0,"atkSpeed":0,"foodCost":0,"manaCost":0,"attackType":"none","buffProvider":"fire","desc":"邻接:赋予燃烧"},
    "cauldron": {"name":"剧毒大锅","icon":"🧪","cost":35,"size":[1,1],"damage":0,"range":0,"atkSpeed":0,"foodCost":0,"manaCost":0,"attackType":"none","buffProvider":"poison","desc":"邻接:赋予中毒"},
    "prism": {"name":"光之棱镜","icon":"🧊","cost":40,"size":[1,1],"damage":0,"range":0,"atkSpeed":0,"foodCost":0,"manaCost":0,"attackType":"none","buffProvider":"range","desc":"邻接:射程+25%"},
    "drum": {"name":"战鼓","icon":"🥁","cost":40,"size":[1,1],"damage":0,"range":0,"atkSpeed":0,"foodCost":0,"manaCost":0,"attackType":"none","buffProvider":"speed","desc":"邻接:攻速+20%"},
    "lens": {"name":"聚光透镜","icon":"🔍","cost":45,"size":[1,1],"damage":0,"range":0,"atkSpeed":0,"foodCost":0,"manaCost":0,"attackType":"none","buffProvider":"crit","desc":"邻接:暴击率+25%"},
    "mirror": {"name":"反射魔镜","icon":"🪞","cost":50,"size":[1,1],"damage":0,"range":0,"atkSpeed":0,"foodCost":0,"manaCost":0,"attackType":"none","buffProvider":"bounce","desc":"邻接:子弹弹射+1"},
    "splitter": {"name":"多重棱镜","icon":"💠","cost":55,"size":[1,1],"damage":0,"range":0,"atkSpeed":0,"foodCost":0,"manaCost":0,"attackType":"none","buffProvider":"split","desc":"邻接:子弹分裂+1"},
    "meat": {"name":"五花肉","icon":"🥓","cost":10,"size":[1,1],"damage":0,"range":0,"atkSpeed":0,"foodCost":0,"manaCost":0,"isFood":true,"xp":50,"attackType":"none","desc":"喂食获得大量Buff"}
}

const TRAITS := [
    {"id":"vamp","name":"吸血","desc":"造成伤害回复生命","icon":"🩸"},
    {"id":"crit","name":"暴击","desc":"20%几率造成双倍伤害","icon":"💥"},
    {"id":"exec","name":"处决","desc":"对生命低于30%的敌人伤害翻倍","icon":"💀"},
    {"id":"giant","name":"巨化","desc":"体型变大，范围增加","icon":"🏔️"},
    {"id":"swift","name":"神速","desc":"攻速 +30%","icon":"👟"}
]

const ENEMY_VARIANTS := {
    "slime": {"name":"史莱姆","icon":"💧","color":Color("#00cec9"),"radius":10,"hpMod":0.8,"spdMod":0.7,"attackType":"melee","range":30,"dmg":5,"atkSpeed":1.0,"drop":"mucus","dropRate":0.5},
    "poison": {"name":"毒怪","icon":"🤢","color":Color("#2ecc71"),"radius":12,"hpMod":1.2,"spdMod":0.8,"attackType":"melee","range":30,"dmg":8,"atkSpeed":1.0,"drop":"poison","dropRate":0.4},
    "wolf": {"name":"狼群","icon":"🐺","color":Color("#e74c3c"),"radius":14,"hpMod":1.0,"spdMod":1.5,"attackType":"melee","range":30,"dmg":12,"atkSpeed":0.8,"drop":"fang","dropRate":0.3},
    "treant": {"name":"树人","icon":"🌳","color":Color("#d35400"),"radius":18,"hpMod":2.5,"spdMod":0.5,"attackType":"melee","range":30,"dmg":20,"atkSpeed":2.0,"drop":"wood","dropRate":0.6},
    "yeti": {"name":"雪怪","icon":"❄️","color":Color("#74b9ff"),"radius":20,"hpMod":3.0,"spdMod":0.6,"attackType":"melee","range":40,"dmg":25,"atkSpeed":2.0,"drop":"snow","dropRate":0.5},
    "golem": {"name":"石头人","icon":"🗿","color":Color("#95a5a6"),"radius":22,"hpMod":4.0,"spdMod":0.4,"attackType":"melee","range":40,"dmg":30,"atkSpeed":2.5,"drop":"stone","dropRate":0.5},
    "shooter": {"name":"投矛手","icon":"🏹","color":Color("#16a085"),"radius":14,"hpMod":0.8,"spdMod":0.8,"attackType":"ranged","range":200,"dmg":8,"atkSpeed":2.0,"projectileSpeed":150,"drop":"wood","dropRate":0.3},
    "boss": {"name":"虚空领主","icon":"👹","color":Color("#2c3e50"),"radius":32,"hpMod":15.0,"spdMod":0.4,"attackType":"melee","range":50,"dmg":50,"atkSpeed":3.0,"drop":"stone","dropRate":1.0}
}

class BattleCanvas:
    extends Control
    var main : Main

    func _ready():
        mouse_filter = Control.MOUSE_FILTER_PASS

    func _draw():
        if main == null:
            return
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        draw_rect(Rect2(Vector2.ZERO, size), COLORS["bg"])
        var center := Vector2(size.x * 0.5, size.y * 0.4)
        for tile_key in main.game["tiles"].keys():
            var tile = main.game["tiles"][tile_key]
            var pos = center + Vector2(tile.x, tile.y) * TILE_SIZE
            var rect = Rect2(pos - Vector2(TILE_SIZE/2, TILE_SIZE/2), Vector2(TILE_SIZE, TILE_SIZE))
            var col = Color(0.3,0.4,0.6) if tile.type == "core" else Color(0.25,0.25,0.35)
            draw_rect(rect, col)
            draw_rect(rect, Color(0.2,0.2,0.3), false, 2.0)
            if tile.type == "core":
                draw_string(get_theme_default_font(), rect.position + Vector2(8, 24), CORE_TYPES[main.game["core_type"]]["icon"], HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
            if tile.unit:
                draw_unit(tile, pos)
        for barricade in main.game["barricades"]:
            var p1 = center + barricade.p1
            var p2 = center + barricade.p2
            draw_line(p1, p2, barricade.props.color, barricade.props.width)
        for enemy in main.game["enemies"]:
            var pos = center + enemy.position
            draw_circle(pos, enemy.radius, enemy.color)
        for proj in main.game["projectiles"]:
            var pos = center + proj.position
            draw_circle(pos, 4, Color.YELLOW)

    func draw_unit(tile, pos: Vector2):
        var unit = tile.unit
        var rect = Rect2(pos - Vector2(TILE_SIZE * unit.size[0] /2, TILE_SIZE * unit.size[1]/2), Vector2(TILE_SIZE * unit.size[0], TILE_SIZE * unit.size[1]))
        draw_rect(rect, Color(0.15,0.35,0.2))
        draw_rect(rect, Color(0.3,0.6,0.3), false, 2)
        var text_pos = rect.position + Vector2(8, 24)
        draw_string(get_theme_default_font(), text_pos, unit.icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)

var game := {
    "core_type": "cornucopia",
    "mode": "normal",
    "food": 100.0,
    "maxFood": 200.0,
    "baseFoodRate": 5.0,
    "mana": 50.0,
    "maxMana": 100.0,
    "baseManaRate": 1.0,
    "gold": 150,
    "wave": 1,
    "isWaveActive": false,
    "waveTime": 0.0,
    "waveDuration": 20.0,
    "tiles": {},
    "bench": [],
    "coreHealth": 100.0,
    "maxCoreHealth": 100.0,
    "enemies": [],
    "projectiles": [],
    "enemyProjectiles": [],
    "particles": [],
    "barricades": [],
    "shop_state": [],
    "tileCost": 50,
    "expansionMode": false,
    "skills": [],
    "shopCollapsed": false,
    "coreCooldown": 0.0,
    "damageStats": {},
    "enemiesToSpawn": 0,
    "totalWaveEnemies": 0,
    "skillCost": 30,
    "materials": {"mucus":0,"poison":0,"fang":0,"wood":0,"snow":0,"stone":0},
    "drawing": {"active":false,"start":null,"current":null,"material":null}
}

var els := {}
var selected_bench_index := -1

func _ready():
    var canvas_node := BattleCanvas.new()
    canvas_node.name = "BattleCanvas"
    canvas_node.main = self
    get_node("Canvas").add_child(canvas_node)
    els["canvas"] = canvas_node
    game["bench"].resize(BENCH_SIZE)
    game["bench"].fill(null)
    build_ui()
    render_selection_screen()

func build_ui():
    var ui := get_node("UI")
    var selection := Control.new()
    selection.name = "Selection"
    selection.anchor_right = 1
    selection.anchor_bottom = 1
    selection.offset_left = 40
    selection.offset_top = 40
    selection.offset_right = -40
    selection.offset_bottom = -40
    var vbox := VBoxContainer.new()
    vbox.anchor_right = 1
    vbox.anchor_bottom = 1
    vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
    vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_theme_constant_override("separation", 10)
    var title := Label.new()
    title.text = "选择你的核心流派"
    title.add_theme_font_size_override("font_size", 32)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(title)
    var cards := GridContainer.new()
    cards.name = "Cards"
    cards.columns = 2
    cards.anchor_right = 1
    cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(cards)
    selection.add_child(vbox)
    ui.add_child(selection)
    els["selection_screen"] = selection
    els["selection_cards"] = cards

    var hud := Control.new()
    hud.name = "HUD"
    hud.anchor_right = 1
    hud.offset_left = 20
    hud.offset_top = 20
    hud.offset_right = -20
    hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hud.visible = false
    var hud_box := HBoxContainer.new()
    hud_box.anchor_right = 1
    hud_box.anchor_bottom = 0
    hud_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hud_box.size_flags_vertical = Control.SIZE_FILL
    hud_box.add_theme_constant_override("separation", 12)
    hud.add_child(hud_box)
    var left := VBoxContainer.new()
    left.custom_minimum_size = Vector2(200, 0)
    hud_box.add_child(left)
    var hp_label := Label.new()
    hp_label.name = "HpLabel"
    left.add_child(hp_label)
    var build_panel := VBoxContainer.new()
    build_panel.name = "BuildPanel"
    left.add_child(build_panel)
    var center := VBoxContainer.new()
    center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    center.alignment = BoxContainer.ALIGNMENT_CENTER
    hud_box.add_child(center)
    var wave_label := Label.new()
    wave_label.name = "WaveLabel"
    center.add_child(wave_label)
    var start_btn := Button.new()
    start_btn.text = "开始下一波"
    start_btn.pressed.connect(start_wave)
    center.add_child(start_btn)
    els["btn_start"] = start_btn
    var right := VBoxContainer.new()
    right.custom_minimum_size = Vector2(200, 0)
    hud_box.add_child(right)
    var resource := Label.new()
    resource.name = "Resource"
    right.add_child(resource)
    ui.add_child(hud)
    els["top_hud"] = hud
    els["hp_text"] = hp_label
    els["wave_text"] = wave_label
    els["resource_text"] = resource
    els["build_panel"] = build_panel

    var bottom := VBoxContainer.new()
    bottom.name = "Bottom"
    bottom.anchor_right = 1
    bottom.anchor_top = 1
    bottom.anchor_bottom = 1
    bottom.offset_left = 20
    bottom.offset_right = -20
    bottom.offset_top = -220
    bottom.offset_bottom = -20
    bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bottom.custom_minimum_size = Vector2(0, 200)
    bottom.visible = false
    var shop_label := Label.new()
    shop_label.text = "补给站"
    shop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    bottom.add_child(shop_label)
    var shop_grid := GridContainer.new()
    shop_grid.name = "ShopGrid"
    shop_grid.columns = 5
    bottom.add_child(shop_grid)
    var bench_grid := HBoxContainer.new()
    bench_grid.name = "Bench"
    bench_grid.add_theme_constant_override("separation", 8)
    bottom.add_child(bench_grid)
    ui.add_child(bottom)
    els["bottom_ui"] = bottom
    els["shop_grid"] = shop_grid
    els["bench_grid"] = bench_grid

    var tooltip := Label.new()
    tooltip.name = "Tooltip"
    tooltip.visible = false
    tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    tooltip.offset_left = 16
    tooltip.offset_top = 16
    ui.add_child(tooltip)
    els["tooltip"] = tooltip

func clear_children(node: Node):
    for c in node.get_children():
        c.queue_free()

func render_selection_screen():
    clear_children(els["selection_cards"])
    for key in CORE_TYPES.keys():
        var info = CORE_TYPES[key]
        var btn := Button.new()
        btn.text = "%s %s" % [info["icon"], info["name"]]
        btn.tooltip_text = info["desc"]
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        btn.pressed.connect(func(): start_game(key))
        els["selection_cards"].add_child(btn)

func start_game(core_type: String):
    game["core_type"] = core_type
    if CORE_TYPES[core_type].has("bonus"):
        var bonus = CORE_TYPES[core_type]["bonus"]
        if bonus.has("foodRate"):
            game["baseFoodRate"] += bonus["foodRate"]
        if bonus.has("manaRate"):
            game["baseManaRate"] += bonus["manaRate"]
    els["selection_screen"].visible = false
    els["top_hud"].visible = true
    els["bottom_ui"].visible = true
    create_tile(0,0,"core")
    create_tile(1,0)
    create_tile(-1,0)
    create_tile(0,1)
    create_tile(0,-1)
    init_build_panel()
    generate_shop_items(true)
    render_shop()
    render_bench()
    update_ui()
    set_process(true)

func create_tile(x:int, y:int, ttype:String="normal"):
    var key := get_tile_key(x,y)
    if game["tiles"].has(key):
        return
    var tile = {"x": x, "y": y, "type": ttype, "unit": null}
    game["tiles"][key] = tile

func get_tile_key(x:int, y:int) -> String:
    return "%s,%s" % [x,y]

func generate_shop_items(force: bool=false):
    if (not force) and game["shop_state"].size() > 0:
        return
    game["shop_state"].clear()
    var pool := UNIT_TYPES.keys()
    pool.shuffle()
    for i in range(min(5, pool.size())):
        game["shop_state"].append(pool[i])

func render_shop():
    clear_children(els["shop_grid"])
    for type_key in game["shop_state"]:
        var info = UNIT_TYPES[type_key]
        var btn := Button.new()
        btn.text = "%s %s (%d)" % [info["icon"], info["name"], info["cost"]]
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        btn.tooltip_text = info["desc"]
        btn.pressed.connect(func(): buy_unit(type_key))
        els["shop_grid"].add_child(btn)

func buy_unit(type_key:String):
    var proto = UNIT_TYPES[type_key]
    if game["gold"] < proto["cost"]:
        return
    var bench_idx = find_empty_bench()
    if bench_idx == -1:
        return
    game["gold"] -= proto["cost"]
    var unit = create_unit_instance(type_key)
    game["bench"][bench_idx] = unit
    render_bench()
    update_ui()

func find_empty_bench() -> int:
    for i in range(BENCH_SIZE):
        if game["bench"][i] == null:
            return i
    return -1

func render_bench():
    clear_children(els["bench_grid"])
    for i in range(BENCH_SIZE):
        var btn := Button.new()
        btn.toggle_mode = true
        if game["bench"][i] == null:
            btn.text = "空位"
        else:
            btn.text = "%s Lv.%d" % [game["bench"][i].icon, game["bench"][i].level]
        btn.pressed.connect(func(idx=i): select_bench(idx))
        if i == selected_bench_index:
            btn.button_pressed = true
        els["bench_grid"].add_child(btn)

func select_bench(idx:int):
    selected_bench_index = idx
    render_bench()

func create_unit_instance(type_key:String) -> Dictionary:
    var proto = UNIT_TYPES[type_key]
    var unit: Dictionary = proto.duplicate(true)
    unit["id"] = str(randi())
    unit["typeKey"] = type_key
    unit["cooldown"] = 0.0
    unit["genCooldown"] = 1.0
    unit["level"] = 1
    unit["statsMultiplier"] = 1.0
    unit["skillCooldown"] = 0.0
    unit["activeBuffs"] = []
    unit["traits"] = []
    unit["rangeMod"] = 1.0
    unit["atkSpeedMod"] = 1.0
    unit["damageMod"] = 1.0
    unit["critChance"] = 0.05
    unit["bounceCount"] = 0
    unit["splitCount"] = 0
    return unit

func update_ui():
    if not els.has("hp_text"):
        return
    els["hp_text"].text = "❤️ 基地核心 %d/%d" % [int(game["coreHealth"]), int(game["maxCoreHealth"])]
    els["wave_text"].text = "Wave %d" % game["wave"]
    els["resource_text"].text = "食物 %.1f / 法力 %.1f / 金币 %d" % [game["food"], game["mana"], game["gold"]]
    update_build_panel_ui()
    els["canvas"].queue_redraw()

func init_build_panel():
    clear_children(els["build_panel"])
    for key in MATERIAL_TYPES.keys():
        var btn := Button.new()
        var mat = MATERIAL_TYPES[key]
        btn.text = "%s %s" % [mat["icon"], mat["name"]]
        btn.pressed.connect(func(): select_build_material(key))
        els["build_panel"].add_child(btn)

func select_build_material(key:String):
    if game["drawing"]["material"] == key:
        game["drawing"]["material"] = null
    else:
        game["drawing"]["material"] = key
    update_build_panel_ui()

func update_build_panel_ui():
    if not els.has("build_panel"):
        return
    var keys := MATERIAL_TYPES.keys()
    for i in range(els["build_panel"].get_child_count()):
        var btn = els["build_panel"].get_child(i)
        if btn is Button:
            var key = keys[i]
            var count = game["materials"][key]
            btn.text = "%s %s (%d)" % [MATERIAL_TYPES[key]["icon"], MATERIAL_TYPES[key]["name"], count]
            btn.disabled = count <= 0 or game["isWaveActive"]

func start_wave():
    if game["isWaveActive"]:
        return
    game["isWaveActive"] = true
    game["enemies"].clear()
    game["projectiles"].clear()
    game["enemyProjectiles"].clear()
    game["waveTime"] = 0.0
    game["enemiesToSpawn"] = 20 + int(game["wave"] * 6)
    game["totalWaveEnemies"] = game["enemiesToSpawn"]
    spawn_enemy_batch()

func spawn_enemy_batch():
    var count: int = min(5, game["enemiesToSpawn"])
    for i in range(count):
        spawn_enemy_at_angle(randf() * TAU, "slime")
        game["enemiesToSpawn"] -= 1
    update_ui()

func spawn_enemy_at_angle(angle:float, variant:String):
    var info = ENEMY_VARIANTS[variant]
    var canvas_size = els["canvas"].size
    var dist = min(canvas_size.x, canvas_size.y) * 0.4
    var pos = Vector2(cos(angle), sin(angle)) * dist
    var enemy = {
        "position": pos,
        "velocity": Vector2.ZERO,
        "radius": info["radius"],
        "hp": info["hpMod"] * 60.0 * (1.0 + (game["wave"]-1)*0.15),
        "speed": 45.0 * info["spdMod"],
        "color": info["color"],
        "variant": variant,
        "atkCooldown": 0.0,
        "attackType": info["attackType"],
        "range": info["range"],
        "dmg": info["dmg"],
        "atkSpeed": info["atkSpeed"]
    }
    game["enemies"].append(enemy)

func _process(delta):
    if not game["isWaveActive"]:
        return
    game["waveTime"] += delta
    update_resources(delta)
    update_units(delta)
    update_enemies(delta)
    update_projectiles(delta)
    els["canvas"].queue_redraw()

func update_resources(delta:float):
    game["food"] = clamp(game["food"] + game["baseFoodRate"] * delta, 0.0, game["maxFood"])
    game["mana"] = clamp(game["mana"] + game["baseManaRate"] * delta, 0.0, game["maxMana"])

func update_units(delta:float):
    for tile in game["tiles"].values():
        if tile.unit == null:
            continue
        var unit = tile.unit
        unit["cooldown"] -= delta
        if unit["cooldown"] <= 0:
            var target = find_nearest_enemy(tile)
            if target != null:
                fire_unit(tile, target)
                unit["cooldown"] = max(0.05, unit["atkSpeed"] * unit["atkSpeedMod"])

func find_nearest_enemy(tile:Dictionary):
    var center := Vector2(els["canvas"].size.x*0.5, els["canvas"].size.y*0.4)
    var tile_pos := center + Vector2(tile.x, tile.y) * TILE_SIZE
    var best: Variant = null
    var best_d := INF
    for enemy in game["enemies"]:
        var pos = center + enemy.position
        var d = tile_pos.distance_to(pos)
        if d < best_d and d <= (tile.unit.range * tile.unit.rangeMod):
            best = enemy
            best_d = d
    return best

func fire_unit(tile:Dictionary, enemy:Dictionary):
    var origin := Vector2(tile.x, tile.y) * TILE_SIZE
    var projectile = {
        "position": origin,
        "velocity": (enemy.position - origin).normalized() * 320.0,
        "damage": tile.unit.damage * tile.unit.damageMod,
        "target": enemy
    }
    game["projectiles"].append(projectile)

func update_projectiles(delta:float):
    var to_remove: Array = []
    for proj in game["projectiles"]:
        proj.position += proj.velocity * delta
        var enemy = proj.target
        if enemy == null:
            to_remove.append(proj)
            continue
        if proj.position.distance_to(enemy.position) < enemy.radius + 2:
            enemy.hp -= proj.damage
            to_remove.append(proj)
    for proj in to_remove:
        game["projectiles"].erase(proj)

func update_enemies(delta:float):
    var center := Vector2.ZERO
    var to_remove: Array = []
    for enemy in game["enemies"]:
        var dir = (center - enemy.position).normalized()
        enemy.position += dir * enemy.speed * delta
        enemy.atkCooldown -= delta
        if enemy.position.length() < 30:
            if enemy.atkCooldown <= 0:
                game["coreHealth"] -= enemy.dmg
                enemy.atkCooldown = enemy.atkSpeed
                if game["coreHealth"] <= 0:
                    game["coreHealth"] = 0
                    game_over()
        if enemy.hp <= 0:
            to_remove.append(enemy)
    for e in to_remove:
        game["enemies"].erase(e)
    if game["enemies"].size() == 0 and game["enemiesToSpawn"] <= 0:
        end_wave()
    elif game["enemiesToSpawn"] > 0 and game["enemies"].size() < 5:
        spawn_enemy_batch()

func end_wave():
    game["isWaveActive"] = false
    game["wave"] += 1
    game["gold"] += 20
    update_ui()

func game_over():
    game["isWaveActive"] = false

func _input(event):
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        handle_click(event.position)

func handle_click(pos: Vector2):
    var center := Vector2(els["canvas"].size.x*0.5, els["canvas"].size.y*0.4)
    var local := pos - center
    var grid_x := roundi(local.x / TILE_SIZE)
    var grid_y := roundi(local.y / TILE_SIZE)
    var key := get_tile_key(grid_x, grid_y)
    if game["tiles"].has(key):
        var tile = game["tiles"][key]
        if selected_bench_index >= 0 and game["bench"][selected_bench_index] != null and tile.unit == null and not game["isWaveActive"]:
            tile.unit = game["bench"][selected_bench_index]
            game["bench"][selected_bench_index] = null
            selected_bench_index = -1
            render_bench()
            recalculate_buffs()
            update_ui()
    else:
        if not game["isWaveActive"] and game["gold"] >= game["tileCost"]:
            create_tile(grid_x, grid_y)
            game["gold"] -= game["tileCost"]
            update_ui()

func recalculate_buffs():
    for tile in game["tiles"].values():
        if tile.unit:
            tile.unit.activeBuffs = []
            tile.unit.rangeMod = 1.0
            tile.unit.atkSpeedMod = 1.0
            tile.unit.damageMod = 1.0
            tile.unit.critChance = 0.05
            tile.unit.bounceCount = 0
            tile.unit.splitCount = 0
    if game["core_type"] == "war":
        for tile in game["tiles"].values():
            if tile.unit:
                tile.unit.damageMod += CORE_TYPES["war"]["bonus"]["globalDmg"]
    for tile in game["tiles"].values():
        if tile.unit == null or not tile.unit.has("buffProvider"):
            continue
        var neighbors = [game["tiles"].get(get_tile_key(tile.x+1, tile.y)), game["tiles"].get(get_tile_key(tile.x-1, tile.y)), game["tiles"].get(get_tile_key(tile.x, tile.y+1)), game["tiles"].get(get_tile_key(tile.x, tile.y-1))]
        for n in neighbors:
            if n != null and n.unit != null and n.unit != tile.unit:
                var buff = tile.unit.buffProvider
                if not n.unit.activeBuffs.has(buff):
                    n.unit.activeBuffs.append(buff)
                    if buff == "range":
                        n.unit.rangeMod += 0.25
                    elif buff == "speed":
                        n.unit.atkSpeedMod *= 0.8
                    elif buff == "crit":
                        n.unit.critChance += 0.25
                    elif buff == "bounce":
                        n.unit.bounceCount += 1
                    elif buff == "split":
                        n.unit.splitCount += 1

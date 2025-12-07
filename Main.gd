extends Node2D

# --- Constants & Configuration ---

const TILE_SIZE = 60
const BENCH_SIZE = 5
const COLORS = {
	"bg": Color("#1a1a2e"),
	"grid": Color("#303045"),
	"enemy": Color("#e74c3c"),
	"projectile": Color("#f1c40f"),
	"enemyProjectile": Color("#e91e63")
}

const UNIT_TYPES = {
	"mouse": { "name": "加特林鼠", "icon": "🐭", "cost": 15, "size": Vector2i(1,1), "damage": 3, "range": 250, "atkSpeed": 0.15, "foodCost": 1.5, "manaCost": 0, "attackType": "ranged", "proj": "dot", "desc": "远程:超快攻速" },
	"turtle": { "name": "狙击龟", "icon": "🐢", "cost": 25, "size": Vector2i(1,1), "damage": 45, "range": 500, "atkSpeed": 1.8, "foodCost": 8, "manaCost": 0, "attackType": "ranged", "proj": "rocket", "desc": "远程:超远单发" },
	"ranger": { "name": "游侠", "icon": "🤠", "cost": 60, "size": Vector2i(1,1), "damage": 12, "range": 180, "atkSpeed": 1.5, "foodCost": 3, "manaCost": 0, "attackType": "ranged", "proj": "pellet", "projCount": 5, "spread": 0.5, "desc": "霰弹:扇形5发" },
	"ninja": { "name": "忍者", "icon": "🥷", "cost": 80, "size": Vector2i(1,1), "damage": 25, "range": 250, "atkSpeed": 0.8, "foodCost": 4, "manaCost": 0, "attackType": "ranged", "proj": "shuriken", "pierce": 3, "desc": "直线穿透3敌" },
	"tesla": { "name": "磁暴线圈", "icon": "⚡", "cost": 70, "size": Vector2i(1,1), "damage": 35, "range": 200, "atkSpeed": 1.2, "foodCost": 5, "manaCost": 5, "attackType": "ranged", "proj": "lightning", "chain": 4, "desc": "攻击产生闪电链" },
	"cannon": { "name": "震荡炮", "icon": "💣", "cost": 90, "size": Vector2i(1,1), "damage": 40, "range": 200, "atkSpeed": 2.0, "foodCost": 8, "manaCost": 0, "attackType": "ranged", "proj": "swarm_wave", "desc": "发射腐臭蜂群" },
	"void": { "name": "奇点", "icon": "🌌", "cost": 200, "size": Vector2i(1,1), "damage": 5, "range": 300, "atkSpeed": 3.0, "foodCost": 15, "manaCost": 20, "attackType": "ranged", "proj": "blackhole", "desc": "发射黑洞(停留吸引)" },
	"knight": { "name": "狂战士", "icon": "🗡️", "cost": 30, "size": Vector2i(1,1), "damage": 20, "range": 100, "atkSpeed": 0.8, "foodCost": 4, "manaCost": 0, "attackType": "melee", "splash": 60, "skill": "rage", "skillCd": 10, "desc": "近战:范围挥砍\n技能:血怒(30💧)" },
	"bear":   { "name": "暴怒熊", "icon": "🐻", "cost": 65, "size": Vector2i(1,1), "damage": 35, "range": 80, "atkSpeed": 1.2, "foodCost": 5, "manaCost": 0, "attackType": "melee", "skill": "stun", "skillCd": 15, "desc": "近战:重击晕眩\n技能:震慑(30💧)" },
	"treant": { "name": "树人守卫", "icon": "🌳", "cost": 40, "size": Vector2i(1,1), "damage": 10, "range": 80, "atkSpeed": 1.5, "foodCost": 2, "manaCost": 0, "attackType": "melee", "desc": "肉盾:高血量" },
	"wizard": { "name": "大法师", "icon": "🧙‍♂️", "cost": 50, "size": Vector2i(1,1), "damage": 60, "range": 350, "atkSpeed": 1.2, "foodCost": 1, "manaCost": 5, "attackType": "ranged", "proj": "orb", "splash": 30, "skill": "nova", "skillCd": 12, "desc": "消耗法力高伤\n技能:新星(30💧)" },
	"phoenix":{ "name": "凤凰", "icon": "🦅", "cost": 150, "size": Vector2i(1,1), "damage": 25, "range": 300, "atkSpeed": 0.6, "foodCost": 10, "manaCost": 0, "attackType": "ranged", "proj": "fire", "splash": 40, "skill": "firestorm", "skillCd": 20, "desc": "远程:AOE轰炸\n技能:火雨(30💧)" },
	"hydra":  { "name": "三头犬", "icon": "🐕", "cost": 120, "size": Vector2i(2,2), "damage": 40, "range": 120, "atkSpeed": 0.8, "foodCost": 20, "manaCost": 0, "attackType": "melee", "skill": "devour_aura", "desc": "2x2巨兽" },
	"plant":  { "name": "向日葵", "icon": "🌻", "cost": 20, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 1.0, "foodCost": -6, "manaCost": 0, "attackType": "none", "produce": "food", "produceAmt": 6, "desc": "产出:食物+6/s" },
	"crystal":{ "name": "法力水晶", "icon": "💎", "cost": 30, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 1.0, "foodCost": 0, "manaCost": -3, "attackType": "none", "produce": "mana", "produceAmt": 3, "desc": "产出:法力+3/s" },
	"torch":  { "name": "红莲火炬", "icon": "🔥", "cost": 35, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 0, "foodCost": 0, "manaCost": 0, "attackType": "none", "buffProvider": "fire", "desc": "邻接:赋予燃烧" },
	"cauldron":{ "name": "剧毒大锅", "icon": "🧪", "cost": 35, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 0, "foodCost": 0, "manaCost": 0, "attackType": "none", "buffProvider": "poison", "desc": "邻接:赋予中毒" },
	"prism":  { "name": "光之棱镜", "icon": "🧊", "cost": 40, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 0, "foodCost": 0, "manaCost": 0, "attackType": "none", "buffProvider": "range", "desc": "邻接:射程+25%" },
	"drum":   { "name": "战鼓", "icon": "🥁", "cost": 40, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 0, "foodCost": 0, "manaCost": 0, "attackType": "none", "buffProvider": "speed", "desc": "邻接:攻速+20%" },
	"lens":   { "name": "聚光透镜", "icon": "🔍", "cost": 45, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 0, "foodCost": 0, "manaCost": 0, "attackType": "none", "buffProvider": "crit", "desc": "邻接:暴击率+25%" },
	"mirror": { "name": "反射魔镜", "icon": "🪞", "cost": 50, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 0, "foodCost": 0, "manaCost": 0, "attackType": "none", "buffProvider": "bounce", "desc": "邻接:子弹弹射+1" },
	"splitter":{ "name": "多重棱镜", "icon": "💠", "cost": 55, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 0, "foodCost": 0, "manaCost": 0, "attackType": "none", "buffProvider": "split", "desc": "邻接:子弹分裂+1" },
	"meat":   { "name": "五花肉", "icon": "🥓", "cost": 10, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 0, "foodCost": 0, "manaCost": 0, "isFood": true, "xp": 50, "attackType": "none", "desc": "喂食获得大量Buff" }
}

const ENEMY_VARIANTS = {
	"slime": { "name": "史莱姆", "icon": "💧", "color": Color("#00cec9"), "radius": 10, "hpMod": 0.8, "spdMod": 0.7, "attackType": "melee", "range": 30, "dmg": 5, "atkSpeed": 1.0, "drop": "mucus", "dropRate": 0.5 },
	"poison":{ "name": "毒怪", "icon": "🤢", "color": Color("#2ecc71"), "radius": 12, "hpMod": 1.2, "spdMod": 0.8, "attackType": "melee", "range": 30, "dmg": 8, "atkSpeed": 1.0, "drop": "poison", "dropRate": 0.4 },
	"wolf":  { "name": "狼群", "icon": "🐺", "color": Color("#e74c3c"), "radius": 14, "hpMod": 1.0, "spdMod": 1.5, "attackType": "melee", "range": 30, "dmg": 12, "atkSpeed": 0.8, "drop": "fang", "dropRate": 0.3 },
	"treant":{ "name": "树人", "icon": "🌳", "color": Color("#d35400"), "radius": 18, "hpMod": 2.5, "spdMod": 0.5, "attackType": "melee", "range": 30, "dmg": 20, "atkSpeed": 2.0, "drop": "wood", "dropRate": 0.6 },
	"yeti":  { "name": "雪怪", "icon": "❄️", "color": Color("#74b9ff"), "radius": 20, "hpMod": 3.0, "spdMod": 0.6, "attackType": "melee", "range": 40, "dmg": 25, "atkSpeed": 2.0, "drop": "snow", "dropRate": 0.5 },
	"golem": { "name": "石头人", "icon": "🗿", "color": Color("#95a5a6"), "radius": 22, "hpMod": 4.0, "spdMod": 0.4, "attackType": "melee", "range": 40, "dmg": 30, "atkSpeed": 2.5, "drop": "stone", "dropRate": 0.5 },
	"shooter":{ "name": "投矛手", "icon": "🏹", "color": Color("#16a085"), "radius": 14, "hpMod": 0.8, "spdMod": 0.8, "attackType": "ranged", "range": 200, "dmg": 8, "atkSpeed": 2.0, "projectileSpeed": 150, "drop": "wood", "dropRate": 0.3 },
	"boss":   { "name": "虚空领主", "icon": "👹", "color": Color("#2c3e50"), "radius": 32, "hpMod": 15.0, "spdMod": 0.4, "attackType": "melee", "range": 50, "dmg": 50, "atkSpeed": 3.0, "drop": "stone", "dropRate": 1.0 }
}

const MATERIAL_TYPES = {
	"mucus": { "name": "粘液", "icon": "💧", "color": Color("#00cec9") },
	"poison":{ "name": "毒药", "icon": "🧪", "color": Color("#2ecc71") },
	"fang":  { "name": "尖牙", "icon": "🦷", "color": Color("#e74c3c") },
	"wood":  { "name": "木头", "icon": "🪵", "color": Color("#d35400") },
	"snow":  { "name": "雪团", "icon": "❄️", "color": Color("#74b9ff") },
	"stone": { "name": "石头", "icon": "🪨", "color": Color("#95a5a6") }
}

# --- Game State ---

var game = {
	"coreType": "cornucopia", "mode": "normal",
	"food": 100.0, "maxFood": 200.0, "baseFoodRate": 5.0,
	"mana": 50.0, "maxMana": 100.0, "baseManaRate": 1.0,
	"gold": 150, "wave": 1, "isWaveActive": false,
	"tiles": {}, # Key: "x,y"
	"enemies": [], # Array of Dicts
	"projectiles": [],
	"enemyProjectiles": [],
	"particles": [],
	"barricades": [],
	"warnings": [],
	"coreHealth": 100.0, "maxCoreHealth": 100.0,
	"materials": { "mucus": 0, "poison": 0, "fang": 0, "wood": 0, "snow": 0, "stone": 0 },
	"enemiesToSpawn": 0, "totalWaveEnemies": 0
}

# --- Rendering Resources ---
var default_font: Font

func _ready():
	default_font = ThemeDB.fallback_font

	# Initial Setup
	create_tile(0, 0, "core")
	create_tile(0, 1, "normal")
	create_tile(0, -1, "normal")
	create_tile(1, 0, "normal")
	create_tile(-1, 0, "normal")

	# For testing, let's auto-place a unit
	place_unit("mouse", 1, 0)

func _process(delta):
	# Game Loop
	update_resources(delta)

	if game.isWaveActive:
		update_units(delta)
		update_enemies(delta)
		update_projectiles(delta)

	update_particles(delta)
	update_warnings(delta)

	queue_redraw()

func _draw():
	# Draw Background
	draw_rect(get_viewport_rect(), COLORS.bg, true)

	var center = get_viewport_rect().size / 2
	# Shift to center
	draw_set_transform(center, 0, Vector2(1, 1))

	# Draw Grid
	for key in game.tiles:
		var tile = game.tiles[key]
		var pos = Vector2(tile.x * TILE_SIZE, tile.y * TILE_SIZE)
		var rect = Rect2(pos - Vector2(TILE_SIZE/2, TILE_SIZE/2), Vector2(TILE_SIZE, TILE_SIZE))

		var color = COLORS.grid
		if tile.type == "core":
			color = Color("#4a3045")

		draw_rect(rect, color, true)
		draw_rect(rect, Color("#4a4a6a"), false, 2.0) # Border

		# Draw Unit
		if tile.unit:
			var unit = tile.unit
			# Draw Emoji
			draw_string_centered(unit.icon, pos, TILE_SIZE * 0.6, Color.WHITE)

			# Draw Level Star
			if unit.level > 1:
				draw_string_centered("⭐" + str(unit.level), pos + Vector2(20, 20), 12, Color.YELLOW)

			# Draw Cooldown/Mana/Food indicators
			if unit.foodCost > 0 and game.food < unit.foodCost:
				draw_string_centered("🚫", pos, 20, Color.RED)

		# Draw Core Icon
		if tile.type == "core":
			draw_string_centered("⚛️", pos, TILE_SIZE * 0.6, Color.WHITE)

	# Draw Barricades
	for b in game.barricades:
		draw_line(b.p1, b.p2, b.props.color, b.props.width)
		# Draw HP bar for walls? (Omitted for brevity as requested mostly core logic)

	# Draw Enemies
	for e in game.enemies:
		draw_string_centered(e.type.icon, Vector2(e.x, e.y), e.radius * 2, Color.WHITE)
		# HP Bar
		var hp_pct = clamp(e.hp / e.maxHp, 0.0, 1.0)
		var bar_pos = Vector2(e.x - 10, e.y - e.radius - 10)
		draw_rect(Rect2(bar_pos, Vector2(20, 4)), Color.RED, true)
		draw_rect(Rect2(bar_pos, Vector2(20 * hp_pct, 4)), Color("#2ecc71"), true)

	# Draw Projectiles
	for p in game.projectiles:
		if p.get("isLightning", false):
			draw_line(Vector2(p.x, p.y), Vector2(p.x, p.y) - Vector2(cos(p.angle), sin(p.angle)) * 30, p.get("color", COLORS.projectile), 2.0)
		elif p.get("projType") == "swarm_wave":
			draw_circle(Vector2(p.x, p.y), 10.0, Color(0, 1, 0, 0.5))
		elif p.get("projType") == "blackhole":
			draw_circle(Vector2(p.x, p.y), 15.0 if p.get("active", false) else 8.0, Color.BLACK)
			draw_circle_outline(Vector2(p.x, p.y), 15.0 if p.get("active", false) else 8.0, Color("#8e44ad"), 2.0)
		else:
			draw_circle(Vector2(p.x, p.y), 4.0, p.get("color", COLORS.projectile))

	# Draw Enemy Projectiles
	for p in game.enemyProjectiles:
		draw_circle(Vector2(p.x, p.y), 4.0, COLORS.enemyProjectile)

	# Draw Particles (Floating Text)
	for p in game.particles:
		var col = p.get("color", Color.WHITE)
		if typeof(col) == TYPE_STRING: col = Color(col)
		col.a = p.alpha
		draw_string_centered(str(p.text), Vector2(p.x, p.y), p.size, col)

	# Draw Warnings
	for w in game.warnings:
		if w.life % 0.2 < 0.1: # Flash
			draw_string_centered(w.icon, Vector2(w.x, w.y), 32, Color.RED)
		draw_string_centered("⚠️", Vector2(w.x, w.y) - Vector2(0, 30), 24, Color.RED)

	# --- UI Overlay (Reset Transform) ---
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 1))

	# Top HUD
	draw_string(default_font, Vector2(20, 30), "WAVE: " + str(game.wave), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	draw_string(default_font, Vector2(20, 60), "Enemies: " + str(game.enemiesToSpawn + game.enemies.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.RED)
	draw_string(default_font, Vector2(20, 90), "Core HP: " + str(int(game.coreHealth)) + "/" + str(int(game.maxCoreHealth)), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.RED)

	# Resources
	draw_string(default_font, Vector2(20, 120), "Food: " + str(int(game.food)) + "/" + str(int(game.maxFood)), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
	draw_string(default_font, Vector2(20, 140), "Mana: " + str(int(game.mana)) + "/" + str(int(game.maxMana)), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.BLUE)
	draw_string(default_font, Vector2(20, 160), "Gold: " + str(game.gold), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.GOLD)

	# Instructions
	if not game.isWaveActive:
		draw_string_centered("Press SPACE to Start Wave", get_viewport_rect().size / 2 - Vector2(0, 150), 32, Color.GREEN)
		draw_string_centered("Left Click to Place 'Mouse' (15g)", get_viewport_rect().size / 2 - Vector2(0, 100), 16, Color.WHITE)


func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var center = get_viewport_rect().size / 2
		var global_m = event.position
		var local_m = global_m - center

		# Convert to tile coords
		var tx = round(local_m.x / TILE_SIZE)
		var ty = round(local_m.y / TILE_SIZE)

		# Simple placement for now
		if not game.isWaveActive:
			place_unit("mouse", tx, ty)

	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		start_wave()

	if event is InputEventKey and event.pressed and event.keycode == KEY_C:
		# Cheat
		game.gold += 1000
		game.food = game.maxFood
		game.mana = game.maxMana
		spawn_floating_text(0, 0, "CHEAT!", Color.PURPLE, 20)

# --- Logic Functions ---

func update_resources(dt):
	if game.food < game.maxFood:
		game.food = min(game.maxFood, game.food + game.baseFoodRate * dt)
	if game.mana < game.maxMana:
		game.mana = min(game.maxMana, game.mana + game.baseManaRate * dt)

func update_units(dt):
	for key in game.tiles:
		var tile = game.tiles[key]
		if not tile.unit: continue
		var u = tile.unit

		if u.cooldown > 0:
			u.cooldown -= dt

		# Produce Logic
		if u.get("produce"):
			if u.genCooldown > 0: u.genCooldown -= dt
			else:
				u.genCooldown = 1.0
				if u.produce == "food":
					game.food = min(game.maxFood, game.food + u.produceAmt)
					spawn_floating_text(tile.x * TILE_SIZE, tile.y * TILE_SIZE, "+" + str(u.produceAmt) + "🌽", Color.YELLOW, 12)
				elif u.produce == "mana":
					game.mana = min(game.maxMana, game.mana + u.produceAmt)
					spawn_floating_text(tile.x * TILE_SIZE, tile.y * TILE_SIZE, "+" + str(u.produceAmt) + "💧", Color.BLUE, 12)

		# Attack Logic
		if u.cooldown <= 0 and u.damage > 0:
			var fCost = u.foodCost if u.foodCost > 0 else 0
			var mCost = u.manaCost if u.manaCost > 0 else 0

			if game.food < fCost or game.mana < mCost:
				continue # Starving or OOM

			var u_pos = Vector2(tile.x * TILE_SIZE, tile.y * TILE_SIZE)
			var target = find_target(u_pos, u.range)

			if target:
				# Consume
				if fCost > 0: game.food -= fCost
				if mCost > 0: game.mana -= mCost
				u.cooldown = u.atkSpeed

				# Fire
				if u.attackType == "ranged":
					spawn_projectile(u, u_pos, target)
				elif u.attackType == "melee":
					# Instant hit logic
					target.hp -= u.damage
					spawn_floating_text(target.x, target.y, str(u.damage), Color.WHITE, 16)
					spawn_particle(target.x, target.y, "⚔️", 20, Color.WHITE)

func find_target(pos, range_val):
	var min_dist = range_val
	var target = null
	for e in game.enemies:
		var d = pos.distance_to(Vector2(e.x, e.y))
		if d < min_dist:
			min_dist = d
			target = e
	return target

func spawn_projectile(unit, start_pos, target):
	var dist = start_pos.distance_to(Vector2(target.x, target.y))
	var speed = 400.0
	if unit.proj == "rocket": speed = 300.0
	var life = (dist / speed) + 0.8

	var p = {
		"x": start_pos.x, "y": start_pos.y,
		"tx": target.x, "ty": target.y,
		"speed": speed,
		"damage": unit.damage,
		"life": life,
		"angle": start_pos.angle_to_point(Vector2(target.x, target.y)),
		"projType": unit.proj,
		"source": unit,
		"hitList": {} # Using dict as set
	}
	game.projectiles.append(p)

func update_projectiles(dt):
	for i in range(game.projectiles.size() - 1, -1, -1):
		var p = game.projectiles[i]

		# Move
		var vx = cos(p.angle) * p.speed
		var vy = sin(p.angle) * p.speed
		p.x += vx * dt
		p.y += vy * dt
		p.life -= dt

		# Collision
		for e in game.enemies:
			if p.hitList.has(e.id): continue
			var d = Vector2(p.x, p.y).distance_to(Vector2(e.x, e.y))
			if d < e.radius + 10:
				e.hp -= p.damage
				spawn_floating_text(e.x, e.y, str(int(p.damage)), Color.WHITE, 16)
				p.hitList[e.id] = true
				if p.projType != "pierce":
					p.life = 0
				break

		if p.life <= 0:
			game.projectiles.remove_at(i)

func update_enemies(dt):
	for i in range(game.enemies.size() - 1, -1, -1):
		var e = game.enemies[i]

		var target_pos = Vector2.ZERO
		var spd = e.speed

		# Barricade Collision / Bypass Logic (Simplified)
		var block_force = Vector2.ZERO

		for b in game.barricades:
			var dist = point_to_line_distance(e.x, e.y, b.p1.x, b.p1.y, b.p2.x, b.p2.y)
			if dist < e.radius + b.props.width + 5:
				# Collision with wall
				# For now, just stop or attack
				if e.get("cooldown", 0) <= 0:
					b.hp -= e.type.dmg
					e.cooldown = e.type.atkSpeed
					spawn_particle((b.p1.x+b.p2.x)/2, (b.p1.y+b.p2.y)/2, "-" + str(e.type.dmg), 14, Color.WHITE)
					if b.hp <= 0:
						game.barricades.erase(b)
				# Stop movement towards core if blocked
				spd = 0

		# Normal Movement
		var pos = Vector2(e.x, e.y)
		var dir = (target_pos - pos).normalized()

		if e.get("cooldown", 0) > 0: e.cooldown -= dt

		e.x += dir.x * spd * dt
		e.y += dir.y * spd * dt

		# Core Hit
		if pos.length() < 30:
			if e.get("cooldown", 0) <= 0:
				game.coreHealth -= e.type.dmg
				e.cooldown = e.type.atkSpeed
				spawn_floating_text(0, 0, "-" + str(e.type.dmg), Color.RED, 24)

			# Push back slightly
			e.x -= dir.x * 5
			e.y -= dir.y * 5

		if game.coreHealth <= 0:
			game.isWaveActive = false
			spawn_floating_text(0, 0, "GAME OVER", Color.RED, 64)

		if e.hp <= 0:
			game.gold += 1
			game.food = min(game.maxFood, game.food + 2)
			spawn_particle(e.x, e.y, "🍖", 16, Color.WHITE)
			game.enemies.remove_at(i)

	if game.enemies.size() == 0 and game.enemiesToSpawn == 0 and game.isWaveActive:
		end_wave()

func point_to_line_distance(px, py, x1, y1, x2, y2):
	var A = px - x1
	var B = py - y1
	var C = x2 - x1
	var D = y2 - y1
	var len_sq = C * C + D * D
	var param = -1.0
	if len_sq != 0: param = (A * C + B * D) / len_sq
	var xx; var yy
	if param < 0:
		xx = x1; yy = y1
	elif param > 1:
		xx = x2; yy = y2
	else:
		xx = x1 + param * C; yy = y1 + param * D
	var dx = px - xx
	var dy = py - yy
	return sqrt(dx * dx + dy * dy)

func update_particles(dt):
	for i in range(game.particles.size() - 1, -1, -1):
		var p = game.particles[i]
		p.x += p.vx
		p.y += p.vy
		p.life -= dt * 2.0
		p.alpha = p.life
		if p.life <= 0:
			game.particles.remove_at(i)

func update_warnings(dt):
	for i in range(game.warnings.size() - 1, -1, -1):
		var w = game.warnings[i]
		w.life -= dt
		if w.life <= 0:
			game.warnings.remove_at(i)

# --- Spawning & Management ---

func start_wave():
	if game.isWaveActive: return
	game.isWaveActive = true
	game.wave += 1
	var count = 5 + game.wave * 2
	game.enemiesToSpawn = count
	game.totalWaveEnemies = count
	spawn_batch_routine()

func spawn_batch_routine():
	# Batches
	var batch_count = 3
	var enemies_per_batch = ceil(float(game.enemiesToSpawn) / batch_count)

	for b in range(batch_count):
		if not game.isWaveActive: break

		# Angle for this batch
		var angle = randf() * TAU
		var dist = 500
		var pos = Vector2(cos(angle), sin(angle)) * dist

		# Warning
		game.warnings.append({"x": pos.x, "y": pos.y, "life": 1.5, "icon": "⚠️"})
		await get_tree().create_timer(1.5).timeout

		if not game.isWaveActive: break

		# Spawn loop
		for k in range(enemies_per_batch):
			if game.enemiesToSpawn <= 0: break
			spawn_enemy_at(angle + randf_range(-0.2, 0.2))
			game.enemiesToSpawn -= 1
			await get_tree().create_timer(0.2).timeout

		await get_tree().create_timer(2.0).timeout

func spawn_enemy_at(angle):
	var dist = 500 # Screen edge approx
	var pos = Vector2(cos(angle), sin(angle)) * dist

	var type_key = "slime"
	var keys = ENEMY_VARIANTS.keys()
	type_key = keys[randi() % keys.size()]

	var type = ENEMY_VARIANTS[type_key]
	var hp = (10 + game.wave * 5) * type.hpMod

	var e = {
		"x": pos.x, "y": pos.y,
		"hp": hp, "maxHp": hp,
		"speed": (40 + game.wave) * type.spdMod,
		"radius": type.radius,
		"type": type,
		"id": randf()
	}
	game.enemies.append(e)

func end_wave():
	game.isWaveActive = false
	spawn_floating_text(0, 0, "Wave Complete!", Color.CYAN, 32)
	game.gold += 50

func create_tile(x, y, type):
	var key = str(x) + "," + str(y)
	game.tiles[key] = {
		"x": x, "y": y, "type": type, "unit": null
	}

func place_unit(type_key, x, y):
	var key = str(x) + "," + str(y)
	if not game.tiles.has(key): return
	var tile = game.tiles[key]
	if tile.unit: return
	if tile.type == "core": return

	var proto = UNIT_TYPES[type_key]
	if game.gold < proto.cost:
		spawn_floating_text(x*TILE_SIZE, y*TILE_SIZE, "No Gold!", Color.RED, 16)
		return

	game.gold -= proto.cost

	var u = proto.duplicate()
	u["level"] = 1
	u["cooldown"] = 0
	u["genCooldown"] = 1.0
	tile.unit = u
	spawn_particle(x*TILE_SIZE, y*TILE_SIZE, "🏗️", 20, Color.WHITE)

func spawn_floating_text(x, y, text, color, size):
	game.particles.append({
		"x": x, "y": y, "text": text, "color": color, "size": size,
		"vx": 0, "vy": -1, "life": 1.0, "alpha": 1.0
	})

func spawn_particle(x, y, text, size, color):
	game.particles.append({
		"x": x, "y": y, "text": text, "color": color, "size": size,
		"vx": randf_range(-1, 1), "vy": randf_range(-2, -0.5), "life": 1.0, "alpha": 1.0
	})

func draw_string_centered(text, pos, size, color):
	var font = default_font
	var str_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
	draw_string(font, pos + Vector2(-str_size.x/2, str_size.y/4), text, HORIZONTAL_ALIGNMENT_CENTER, -1, size, color)

func draw_circle_outline(pos, radius, color, width):
	draw_arc(pos, radius, 0, TAU, 32, color, width)

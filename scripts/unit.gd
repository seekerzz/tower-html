extends Node2D

class_name Unit

var type_key: String
var level: int = 1
var grid_pos: Vector2i
var stats = {}
var cooldown: float = 0.0
var unit_name: String = "Unit"

func initialize(key: String, _level: int = 1):
	type_key = key
	level = _level
	var proto = UnitData.UNIT_TYPES[key]
	unit_name = proto.name

	# Load base stats and apply level multiplier
	stats = proto.duplicate()
	# Simple level scaling
	if level > 1:
		stats.damage = stats.damage * (1.0 + (level - 1) * 0.5)

	queue_redraw()

func _process(delta):
	if !GameManager.is_wave_active:
		return

	if cooldown > 0:
		cooldown -= delta
		return

	if stats.damage > 0: # Only attack if damage > 0
		var target = find_target()
		if target:
			attack(target)

	# Producer logic
	if stats.has("produce"):
		# In ref, producers have a separate cooldown
		# Simplified here: assume same cooldown or add a separate one.
		# Ref uses `genCooldown`.
		pass

func find_target():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest = null
	var min_dist = stats.range

	for enemy in enemies:
		var dist = position.distance_to(enemy.position)
		if dist <= min_dist:
			min_dist = dist
			closest = enemy

	return closest

func attack(target):
	if stats.food_cost > 0 and !GameManager.spend_food(stats.food_cost):
		return # Starving

	if stats.mana_cost > 0 and !GameManager.spend_mana(stats.mana_cost):
		return # No mana

	cooldown = stats.atk_speed

	if stats.attack_type == "melee":
		# Instant damage
		target.take_damage(stats.damage)
	elif stats.attack_type == "ranged":
		var proj = load("res://scenes/projectile.tscn").instantiate()
		proj.position = position
		proj.target = target
		proj.damage = stats.damage
		proj.speed = 400.0 # Could vary by unit
		get_parent().get_parent().get_node("ProjectileLayer").add_child(proj)

func _draw():
	# Draw unit visual
	var size = stats.get("size", Vector2i(1,1))
	var rect_size = Vector2(size) * 64.0 # TILE_SIZE
	var rect = Rect2(-rect_size/2, rect_size)

	draw_rect(rect, Color(0.2, 0.2, 0.2)) # Back
	draw_rect(rect.grow(-4), Color.WHITE) # Inner

	# Draw Icon
	var font = ThemeDB.fallback_font
	var icon = stats.get("icon", "?")
	draw_string(font, Vector2(-10, 10), icon, HORIZONTAL_ALIGNMENT_CENTER, -1, 32)

	# Draw Level stars
	if level > 1:
		draw_string(font, Vector2(10, 20), "⭐%d" % level, HORIZONTAL_ALIGNMENT_RIGHT, -1, 12)

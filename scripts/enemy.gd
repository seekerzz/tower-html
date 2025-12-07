extends CharacterBody2D

class_name Enemy

var type_data = {}
var current_hp: float
var max_hp: float
var speed: float
var radius: float = 10.0
var target_core = Vector2.ZERO
var hit_barriers = []
var bypass_dest = null
var effects = {}

var is_active: bool = true

func initialize(data: Dictionary, wave: int):
	type_data = data

	# Logic from ref.html: baseHp = 10 + (wave * 8); hp = baseHp * hpMod
	var base_hp = 10 + (wave * 8)
	max_hp = base_hp * data.get("hp_mod", 1.0)
	current_hp = max_hp

	# Logic from ref.html: speed = (40 + (wave * 2)) * spdMod
	var base_speed = 40 + (wave * 2)
	speed = base_speed * data.get("spd_mod", 1.0)

	radius = data.get("radius", 10.0)

	# Set visual properties (placeholder)
	queue_redraw()

func _physics_process(delta):
	if !is_active: return

	# Apply effects
	handle_effects(delta)

	if current_hp <= 0:
		die()
		return

	move_towards_core(delta)

func handle_effects(delta):
	if effects.has("slow"):
		speed = type_data.speed * 0.5
		effects["slow"] -= delta
		if effects["slow"] <= 0:
			effects.erase("slow")
			speed = type_data.speed
	# Implement burn, poison etc.

func move_towards_core(delta):
	var direction = (target_core - position).normalized()
	velocity = direction * speed

	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider is Barricade:
			attack_barricade(collider)

	if position.distance_to(target_core) < 30:
		attack_core()

func attack_barricade(barricade):
	# Simple attack logic
	barricade.take_damage(type_data.dmg * 0.1) # Reduce dmg vs walls?
	# Bounce back
	var bounce = (position - barricade.position).normalized() * 10
	position += bounce

func attack_core():
	GameManager.damage_core(type_data.dmg)
	# Push back slightly
	var push = (position - target_core).normalized() * 50
	position += push

	# Die on impact? Or attack repeatedly? Ref says attack then push back
	# "game.coreHealth -= e.type.dmg ... e.x -= Math.cos(angle) * 5"
	# It keeps attacking.

func take_damage(amount: float):
	current_hp -= amount
	# Flash effect etc.

func die():
	is_active = false
	GameManager.add_gold(1)
	GameManager.add_material(type_data.get("drop", "wood"), 1) # Probability check needed
	queue_free()

func _draw():
	var color = Color.RED
	if type_data.has("color"):
		color = Color.from_string(type_data.color, Color.RED)
	draw_circle(Vector2.ZERO, radius, color)

	# HP Bar
	var hp_pct = current_hp / max_hp
	draw_rect(Rect2(-10, -radius - 5, 20, 3), Color.RED)
	draw_rect(Rect2(-10, -radius - 5, 20 * hp_pct, 3), Color.GREEN)

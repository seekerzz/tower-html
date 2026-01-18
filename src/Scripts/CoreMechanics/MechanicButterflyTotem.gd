extends "res://src/Scripts/CoreMechanics/CoreMechanic.gd"

# Config - Adjustable via Inspector if desired, but here hardcoded defaults as per request
var ORB_COUNT: int = 3
var ORBIT_RADIUS_TILES: int = 3
var ROTATION_SPEED: float = 2.0 # Rad/s
var ORB_DAMAGE: float = 20.0
var MANA_GAIN: float = 20.0
var REHIT_INTERVAL: float = 0.5

# State
var orbs: Array = []
var current_angle: float = 0.0
var rehit_timer: float = 0.0
var behavior = self # For Projectile callback (Duck Typing)

# Mock Unit Properties for CombatManager compatibility
var unit_data = {
	"damageType": "magic",
	"proj": "pearl"
}
var damage: float = 20.0 # Base damage
var crit_rate: float = 0.0
var crit_dmg: float = 1.5

func _ready():
	damage = ORB_DAMAGE
	_try_spawn_orbs()

func on_wave_started():
	_try_spawn_orbs()

func _process(delta):
	# Ensure orbs exist (retry if failed earlier)
	if orbs.size() < ORB_COUNT:
		_try_spawn_orbs()

	# Clean up invalid orbs
	var valid_orbs = []
	for orb in orbs:
		if is_instance_valid(orb):
			valid_orbs.append(orb)
	orbs = valid_orbs

	if orbs.is_empty(): return

	# Rotation
	current_angle += ROTATION_SPEED * delta
	current_angle = fmod(current_angle, TAU)

	# Update Position
	var center = Vector2.ZERO
	if GameManager.grid_manager:
		center = GameManager.grid_manager.to_global(Vector2.ZERO)

	var radius_px = ORBIT_RADIUS_TILES * Constants.TILE_SIZE

	for i in range(orbs.size()):
		var orb = orbs[i]
		var angle_offset = (TAU / float(ORB_COUNT)) * i
		var total_angle = current_angle + angle_offset
		var pos = center + Vector2(cos(total_angle), sin(total_angle)) * radius_px

		# Force position
		orb.global_position = pos
		orb.rotation = total_angle # Optional: Rotate projectile to face tangent? Or face out?
		# Usually rotation follows movement direction, but here we orbit.
		# Let's just update position. Projectile visual might have its own rotation.

	# Rehit Logic
	rehit_timer -= delta
	if rehit_timer <= 0:
		rehit_timer = REHIT_INTERVAL
		for orb in orbs:
			orb.hit_list.clear()
			if orb.shared_hit_list_ref != null:
				orb.shared_hit_list_ref.clear()

func _try_spawn_orbs():
	if orbs.size() >= ORB_COUNT: return
	if !GameManager.combat_manager: return
	if !GameManager.grid_manager: return

	# Clear existing to restart cleanly
	for o in orbs:
		if is_instance_valid(o): o.queue_free()
	orbs.clear()

	var center = GameManager.grid_manager.to_global(Vector2.ZERO)

	for i in range(ORB_COUNT):
		var stats = {
			"pierce": 9999,
			"life": 9999,
			"speed": 0.0, # Prevent default movement
			"type": "pearl",
			"damage": ORB_DAMAGE
		}

		var proj = GameManager.combat_manager.spawn_projectile(self, center, null, stats)
		orbs.append(proj)

func on_projectile_hit(target, _damage_amount, _projectile):
	GameManager.add_mana(MANA_GAIN)

func calculate_damage_against(_target):
	return ORB_DAMAGE

func _exit_tree():
	for orb in orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	orbs.clear()

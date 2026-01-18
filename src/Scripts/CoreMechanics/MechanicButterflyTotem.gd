extends "res://src/Scripts/CoreMechanics/CoreMechanic.gd"

# Configuration
const ORB_COUNT = 3
const ORBIT_RADIUS_TILES = 3
const ROTATION_SPEED = 2.0 # Radians per second
const ORB_DAMAGE = 20.0
const MANA_GAIN = 20.0
const REHIT_INTERVAL = 0.5

# Runtime State
var orbs = []
var orbit_angle = 0.0
var timer: Timer

# Duck Typing for CombatManager (Source Unit Mock)
var unit_data = {
	"proj": "orb", # Fallback, though we specify it in spawn
	"damageType": "magic"
}
var crit_rate = 0.0
var crit_dmg = 1.5
var active_buffs = []
var behavior = self

func _ready():
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = REHIT_INTERVAL
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

	# Defer spawning to ensure other systems are ready if needed
	call_deferred("spawn_orbs")

func spawn_orbs():
	# Clear existing orbs if any (though usually this script is fresh)
	for orb in orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	orbs.clear()

	var combat_mgr = GameManager.combat_manager
	if not combat_mgr:
		print("MechanicButterflyTotem: CombatManager not found.")
		return

	for i in range(ORB_COUNT):
		# We spawn the projectile.
		# Params: source_unit (self), pos (temp), target (null), extra_stats
		var extra_stats = {
			"damage": ORB_DAMAGE,
			"pierce": 9999,
			"life": 9999.0,
			"type": "pearl", # Using "pearl" or "orb" as requested. "pearl" likely fits visuals if exists, else it might default.
			"knockback": 0 # Optional
		}

		# Initial position doesn't matter much as we update it in _process immediately
		var proj = combat_mgr.spawn_projectile(self, Vector2.ZERO, null, extra_stats)
		if proj:
			orbs.append(proj)
			# Hide default projectile visual if we wanted custom, but Projectile.gd handles types.
			# Assuming "pearl" or default type handles visuals.

func _process(delta):
	orbit_angle += ROTATION_SPEED * delta

	# Determine Core Position
	var core_pos = Vector2.ZERO
	if GameManager.grid_manager and GameManager.grid_manager.tiles.has("0,0"):
		core_pos = GameManager.grid_manager.tiles["0,0"].global_position

	var radius_pixels = ORBIT_RADIUS_TILES * Constants.TILE_SIZE

	for i in range(orbs.size()):
		var orb = orbs[i]
		if is_instance_valid(orb):
			# Distribute orbs evenly
			var angle_offset = (TAU / ORB_COUNT) * i
			var current_orb_angle = orbit_angle + angle_offset

			var offset = Vector2(cos(current_orb_angle), sin(current_orb_angle)) * radius_pixels
			orb.global_position = core_pos + offset

			# Optional: Rotate orb to face movement direction (tangent)
			# Tangent is angle + 90 degrees (PI/2)
			orb.rotation = current_orb_angle + PI / 2.0
		else:
			# If an orb was destroyed (e.g. by game logic), we might want to respawn it?
			# For now, we assume they last indefinitely.
			pass

func _on_timer_timeout():
	for orb in orbs:
		if is_instance_valid(orb):
			# Reset hit list to allow re-hitting enemies
			if "hit_list" in orb:
				orb.hit_list.clear()

# Callback from Projectile.gd when it hits an enemy
func on_projectile_hit(_target, _damage, _projectile):
	GameManager.add_mana(MANA_GAIN)

# Mock method for CombatManager if it calls calculate_damage_against
func calculate_damage_against(_target):
	return ORB_DAMAGE

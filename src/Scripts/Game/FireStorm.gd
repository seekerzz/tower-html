extends Node2D

@export var duration: float = 5.0
@export var wave_interval: float = 0.4
@export var damage_per_tick: float = 15.0
@export var area_size: Vector2 = Vector2(200, 200)

var _time_active: float = 0.0
var _wave_timer: float = 0.0
var _damage_timer: float = 0.0

@onready var rain_particles: GPUParticles2D = $RainParticles
@onready var ground_burn_particles: GPUParticles2D = $GroundBurnParticles
# Explosion particles are handled as sub-emitters of RainParticles

func init(dmg: float):
	damage_per_tick = dmg

func _ready():
	# Configure area size visually if possible, or just assume particles are set up correctly.
	# We could update particle emission extents here if we wanted dynamic size.
	if ground_burn_particles:
		# Update emission box size if needed
		var mat = ground_burn_particles.process_material as ParticleProcessMaterial
		if mat:
			mat.emission_box_extents = Vector3(area_size.x / 2, area_size.y / 2, 1)

	if rain_particles:
		var mat = rain_particles.process_material as ParticleProcessMaterial
		if mat:
			mat.emission_box_extents = Vector3(area_size.x / 2, area_size.y / 2, 1)

		rain_particles.one_shot = true
		rain_particles.emitting = false

	# Initial wave
	_trigger_wave()

func _process(delta):
	_time_active += delta
	if _time_active >= duration:
		_end_effect()
		return

	# Wave logic
	_wave_timer += delta
	if _wave_timer >= wave_interval:
		_wave_timer = 0.0
		_trigger_wave()

	# Damage logic
	_damage_timer += delta
	if _damage_timer >= 0.5:
		_damage_timer = 0.0
		_deal_damage()

func _trigger_wave():
	if rain_particles:
		rain_particles.restart()

func _deal_damage():
	# Use PhysicsServer or Area2D to detect enemies.
	# Since we don't have a persistent Area2D in the refactored scene yet,
	# we should probably add one or use the physics server.
	# For simplicity, let's look for an Area2D named "DamageArea".

	var area = get_node_or_null("DamageArea")
	if not area:
		return

	var bodies = area.get_overlapping_areas() + area.get_overlapping_bodies()

	for body in bodies:
		# Check if parent is enemy
		var target = body
		if body.get_parent().is_in_group("enemies"):
			target = body.get_parent()

		if target.is_in_group("enemies") and target.has_method("take_damage"):
			target.take_damage(damage_per_tick, self, "fire")

func _end_effect():
	set_process(false)
	if ground_burn_particles: ground_burn_particles.emitting = false
	if rain_particles: rain_particles.emitting = false

	# Allow particles to fade out
	await get_tree().create_timer(2.0).timeout
	queue_free()

# Callback for Camera Shake - called by RainParticles script or logic?
# Actually, it's better if we just shake periodically or when damage happens.
# The user asked: "At the moment fireball hits ground...".
# Since we use particles for visuals, we don't have a callback for each particle hit easily without script on particles.
# But since we trigger waves, we can sync the shake with the wave hit (delayed by fall time).
func _trigger_camera_shake():
	var camera = get_viewport().get_camera_2d()
	if camera:
		if camera.has_method("shake"):
			camera.shake(3.0, 0.3)
		elif camera.has_method("apply_shake"):
			camera.apply_shake(3.0)

# We can schedule a shake after wave trigger + fall time
func _schedule_impact_shake():
	# Assuming fall time is approx 0.5s based on gravity/height
	await get_tree().create_timer(0.4).timeout
	_trigger_camera_shake()

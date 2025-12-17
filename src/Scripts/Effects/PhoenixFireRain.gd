extends Node2D

@export var duration: float = 10.0
@export var damage_per_tick: float = 10.0
@export var area_size: Vector2 = Vector2(180, 180)
@export var particle_amount: int = 100

var falling_particles: GPUParticles2D
var explosion_particles: GPUParticles2D
var burning_particles: GPUParticles2D
var damage_area: Area2D

var time_elapsed: float = 0.0
var tick_timer: float = 0.0
var fps_check_timer: float = 1.0

func init(dmg: float):
	damage_per_tick = dmg

func _ready():
	# Create shared texture
	var particle_texture = _create_soft_glow_texture()

	# 1. Burning Layer (Bottom) - AOE Indicator
	setup_burning_layer(particle_texture)

	# 2. Explosion Layer (Middle - triggered by falling)
	setup_explosion_layer(particle_texture)

	# 3. Falling Layer (Top)
	setup_falling_layer(particle_texture)

	# 4. Logic & Physics
	setup_logic()

func setup_logic():
	damage_area = Area2D.new()
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = area_size
	shape.shape = rect
	damage_area.add_child(shape)
	add_child(damage_area)

	# Store area for processing (keeping compatibility with FireStorm logic if needed externally)
	set_meta("damage_area", damage_area)

func setup_burning_layer(tex: Texture2D):
	burning_particles = GPUParticles2D.new()
	burning_particles.name = "BurningParticles"
	burning_particles.amount = 50
	burning_particles.lifetime = 1.5
	burning_particles.texture = tex

	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(area_size.x/2, area_size.y/2, 1)
	mat.gravity = Vector3(0, -20, 0) # Rising smoke/fire
	mat.scale_min = 2.0
	mat.scale_max = 4.0

	# Color Ramp (Fire)
	var grad = Gradient.new()
	grad.set_color(0, Color(1, 0.2, 0, 0.6)) # Red-Orange
	grad.set_color(1, Color(0.1, 0.1, 0.1, 0)) # Fade to black smoke
	var grad_tex = GradientTexture1D.new()
	grad_tex.gradient = grad
	mat.color_ramp = grad_tex

	burning_particles.process_material = mat
	add_child(burning_particles)

func setup_explosion_layer(tex: Texture2D):
	explosion_particles = GPUParticles2D.new()
	explosion_particles.name = "ExplosionParticles"
	explosion_particles.amount = 100 # Pool for explosions
	explosion_particles.lifetime = 0.5
	explosion_particles.explosiveness = 1.0 # Burst
	explosion_particles.texture = tex

	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 60.0
	mat.initial_velocity_max = 120.0
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 0.5
	mat.scale_max = 1.5

	# Color (Bright flash)
	var grad = Gradient.new()
	grad.set_color(0, Color(1, 1, 0.5, 1))
	grad.set_color(1, Color(1, 0.5, 0, 0))
	var grad_tex = GradientTexture1D.new()
	grad_tex.gradient = grad
	mat.color_ramp = grad_tex

	explosion_particles.process_material = mat
	explosion_particles.emitting = false # Only emit via sub-emitter
	add_child(explosion_particles)

func setup_falling_layer(tex: Texture2D):
	falling_particles = GPUParticles2D.new()
	falling_particles.name = "FallingParticles"
	falling_particles.amount = particle_amount
	# Calculate physics for falling
	var height = 400.0
	var gravity_val = 2000.0
	# t = sqrt(2*d/a)
	var fall_time = sqrt(2.0 * height / gravity_val)

	falling_particles.position.y = -height
	falling_particles.lifetime = fall_time
	falling_particles.explosiveness = 0.0 # Continuous rain
	# But to simulate "Waves", we might want slight modulation, or just rely on high gravity and emission rate

	falling_particles.texture = tex
	falling_particles.trail_enabled = true
	falling_particles.trail_lifetime = 0.1
	falling_particles.trail_sections = 4 # Default

	var mat = ParticleProcessMaterial.new()
	# Emit from above, covering the area below
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(area_size.x/2, area_size.y/2, 1)

	# Physics: Gravity
	mat.gravity = Vector3(0, gravity_val, 0) # High gravity for "smash" feel
	# Align to velocity for trails
	mat.particle_flag_align_y = true

	# Sub-emitter
	# Link to the explosion particles
	# Note: In Godot 4, sub_emitter expects a node path relative to the particle node
	falling_particles.sub_emitter = NodePath("../ExplosionParticles")
	mat.sub_emitter_mode = ParticleProcessMaterial.SUB_EMITTER_AT_END

	# Color
	var grad = Gradient.new()
	grad.set_color(0, Color(1, 1, 0, 1))
	grad.set_color(1, Color(1, 0.2, 0, 1))
	var grad_tex = GradientTexture1D.new()
	grad_tex.gradient = grad
	mat.color_ramp = grad_tex

	falling_particles.process_material = mat
	add_child(falling_particles)

func _create_soft_glow_texture() -> Texture2D:
	var tex = GradientTexture2D.new()
	tex.width = 32
	tex.height = 32
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	var grad = Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	tex.gradient = grad
	return tex

func _process(delta):
	# Camera Shake trigger check (simulated based on particle count or timer)
	# Ideally, we trigger shake when a wave hits.
	# Since it's continuous, we can trigger small shakes periodically.
	if falling_particles.emitting and randf() < 0.1:
		_trigger_camera_shake()

	time_elapsed += delta
	if time_elapsed > duration:
		falling_particles.emitting = false
		burning_particles.emitting = false

		# Let remaining particles finish
		set_process(false)
		get_tree().create_timer(2.0).timeout.connect(queue_free)
		return

	tick_timer -= delta
	if tick_timer <= 0:
		tick_timer = 0.5
		_deal_damage()

	# FPS Monitoring and Adaptation
	fps_check_timer -= delta
	if fps_check_timer <= 0:
		fps_check_timer = 1.0
		if Engine.get_frames_per_second() < 30 and falling_particles.amount > 10:
			falling_particles.amount = int(falling_particles.amount * 0.8)
			print("Warning: Low FPS, reducing particle count to ", falling_particles.amount)

func _deal_damage():
	if !damage_area: return

	var bodies = damage_area.get_overlapping_areas()
	bodies.append_array(damage_area.get_overlapping_bodies())

	for body in bodies:
		var target = body
		# Check if parent is the actual unit (common in Godot structure)
		if body.get_parent().is_in_group("enemies"):
			target = body.get_parent()
		elif body.is_in_group("enemies"):
			target = body

		if target.has_method("take_damage"):
			target.take_damage(damage_per_tick, self, "fire")

func _trigger_camera_shake():
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(0.2, 2.0)
	elif camera and camera.has_method("apply_shake"):
		camera.apply_shake(2.0)

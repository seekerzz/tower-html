extends Node2D

var duration: float = 5.0
var tick_timer: float = 0.0
var damage_per_tick: float = 0.0

# VFX Nodes
var rain_particles: GPUParticles2D
var explosion_particles: GPUParticles2D
var scorch_particles: GPUParticles2D
var wave_timer: Timer

# FPS Monitor
var fps_check_timer: float = 0.0
const FPS_CHECK_INTERVAL: float = 1.0

func init(dmg: float):
	damage_per_tick = dmg

	# 1. Scorch/Ground Burning (AOE Indicator)
	# Continuous emission on the ground
	scorch_particles = GPUParticles2D.new()
	scorch_particles.name = "ScorchParticles"
	var scorch_mat = ParticleProcessMaterial.new()
	scorch_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	scorch_mat.emission_box_extents = Vector3(90, 90, 1) # Area size 180x180
	scorch_mat.gravity = Vector3(0, 0, 0)
	scorch_mat.color_ramp = load_gradient("res://assets/vfx/fire/scorch_mark.tres")
	scorch_mat.alpha_curve = curve_fade_in_out() # Helper to create curve
	scorch_particles.process_material = scorch_mat
	scorch_particles.amount = 20 # Low amount, just to mark area
	scorch_particles.lifetime = 2.0
	scorch_particles.texture = load_texture("res://assets/vfx/fire/scorch_mark.tres") # Reusing gradient as texture
	add_child(scorch_particles)

	# 2. Explosion Particles (Sub-emitter)
	# This needs to be in the tree to be referenced by path
	explosion_particles = GPUParticles2D.new()
	explosion_particles.name = "ExplosionParticles"
	var exp_mat = ParticleProcessMaterial.new()
	exp_mat.direction = Vector3(0, -1, 0)
	exp_mat.spread = 180.0
	exp_mat.initial_velocity_min = 50.0
	exp_mat.initial_velocity_max = 100.0
	exp_mat.gravity = Vector3(0, 0, 0)
	exp_mat.scale_min = 2.0
	exp_mat.scale_max = 4.0
	exp_mat.color_ramp = load_gradient("res://assets/vfx/fire/fire_explosion.tres")
	explosion_particles.process_material = exp_mat
	explosion_particles.texture = load_texture("res://assets/vfx/fire/fire_explosion.tres")
	explosion_particles.amount = 100 # Pool size
	explosion_particles.lifetime = 0.5
	explosion_particles.explosiveness = 1.0
	# For sub-emitters to work in GPUParticles2D, the node must be emitting.
	# We rely on sub-emission to spawn particles.
	explosion_particles.emitting = true
	add_child(explosion_particles)

	# 3. Rain Particles (Falling Projectiles)
	rain_particles = GPUParticles2D.new()
	rain_particles.name = "RainParticles"
	var rain_mat = ParticleProcessMaterial.new()
	rain_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rain_mat.emission_box_extents = Vector3(90, 1, 1) # Thin box for rain line if 2D, but we want 90 wide.

	rain_mat.direction = Vector3(0, 1, 0) # Down
	rain_mat.spread = 0.0
	# Physics: High gravity. Start high above.
	# Let's say we spawn them at y = -500 relative to this node.
	# Gravity = 980 (standard) * 2 = 1960 for "High gravity"
	rain_mat.gravity = Vector3(0, 2000, 0)

	# Trail setup
	rain_mat.scale_min = 2.0
	rain_mat.scale_max = 3.0
	rain_mat.color_ramp = load_gradient("res://assets/vfx/fire/fire_trail.tres")
	rain_mat.turbulence_enabled = true
	rain_mat.turbulence_noise_strength = 2.0

	# Sub-emitter setup
	rain_mat.sub_emitter_mode = ParticleProcessMaterial.SUB_EMITTER_AT_END
	rain_mat.sub_emitter_keep_velocity = false

	rain_particles.process_material = rain_mat
	rain_particles.texture = load_texture("res://assets/vfx/fire/fire_trail.tres")
	rain_particles.amount = 50
	rain_particles.lifetime = 0.7 # Calculated to hit ground

	# We need to offset the emission area visually.
	rain_particles.position = Vector2(0, -500)

	# Link sub-emitter
	# NodePath must be relative to the particle node
	rain_particles.sub_emitter = NodePath("../ExplosionParticles")

	add_child(rain_particles)

	# Wave/Burst Logic
	rain_particles.emitting = false
	rain_particles.one_shot = false # We control emitting manually

	wave_timer = Timer.new()
	wave_timer.wait_time = 0.8 # Wave every 0.8 seconds (giving enough time for particles to land and clear visually if needed, but we overlap waves)
	wave_timer.one_shot = false
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	add_child(wave_timer)
	wave_timer.start()

	# Trigger first wave
	_on_wave_timer_timeout()

	# Detection Area (Same as before)
	var area = Area2D.new()
	var shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(180, 180)
	shape.shape = rect_shape
	area.add_child(shape)
	add_child(area)
	self.set_meta("damage_area", area)

func _process(delta):
	duration -= delta
	if duration <= 0:
		queue_free()
		return

	tick_timer -= delta
	if tick_timer <= 0:
		tick_timer = 0.5
		_deal_damage()

	# FPS Check with cooldown
	fps_check_timer += delta
	if fps_check_timer >= FPS_CHECK_INTERVAL:
		fps_check_timer = 0.0
		monitor_fps()

func _on_wave_timer_timeout():
	if not is_instance_valid(rain_particles): return

	# Start emitting for a short burst
	rain_particles.emitting = true

	# Create a tween or timer to stop emission
	var t = get_tree().create_timer(0.2)
	t.timeout.connect(func(): if is_instance_valid(rain_particles): rain_particles.emitting = false)

	# Trigger Camera Shake on impact?
	# Impact happens 'lifetime' seconds later.
	get_tree().create_timer(rain_particles.lifetime).timeout.connect(_on_impact)

func _on_impact():
	# Camera Shake
	if GameManager.main_game and GameManager.main_game.has_method("shake_camera"):
		GameManager.main_game.shake_camera(3.0, 0.2)

func _deal_damage():
	var area = get_meta("damage_area")
	if !area: return

	var bodies = area.get_overlapping_areas()
	bodies.append_array(area.get_overlapping_bodies())

	for body in bodies:
		var enemy = body.get_parent()
		if enemy.is_in_group("enemies"):
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage_per_tick, self, "fire")
		elif body.is_in_group("enemies"):
			if body.has_method("take_damage"):
				body.take_damage(damage_per_tick, self, "fire")

# FPS Monitoring
func monitor_fps():
	var fps = Engine.get_frames_per_second()
	if fps < 30:
		# Reduce amount if high
		if rain_particles.amount > 10:
			print("FPS Low (%d). Reducing particle count." % fps)
			rain_particles.amount = int(rain_particles.amount * 0.8)
		if explosion_particles.amount > 20:
			explosion_particles.amount = int(explosion_particles.amount * 0.8)

# Helpers
func load_gradient(path: String) -> GradientTexture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func curve_fade_in_out() -> CurveTexture:
	var curve = Curve.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(0.2, 1))
	curve.add_point(Vector2(1, 0))
	var texture = CurveTexture.new()
	texture.curve = curve
	return texture

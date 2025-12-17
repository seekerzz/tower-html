extends Node2D

var skill_instance: Node2D = null
var elapsed: float = 0.0

func _ready():
	print("Starting Phoenix Fire Rain Test...")
	# Instantiate the skill
	var scene = load("res://src/Scenes/Effects/PhoenixFireRain.tscn")
	if scene:
		skill_instance = scene.instantiate()
		skill_instance.position = Vector2(400, 300)
		skill_instance.duration = 10.0 # Requirement: 10 seconds
		skill_instance.particle_amount = 200 # Heavy rain for stress test
		add_child(skill_instance)
		print("Skill instantiated.")
	else:
		printerr("Failed to load skill scene!")

func _process(delta):
	elapsed += delta

	if skill_instance:
		var falling = skill_instance.get("falling_particles") as GPUParticles2D
		if falling:
			# Verify emission count/shape logic (indirectly via amount)
			if falling.emitting:
				# Requirement: Monitor particle count and duration
				# We cannot easily count active particles in script in Godot 4 without GPU feedback,
				# but we can check if emitting is true and FPS is stable.
				pass
			else:
				if elapsed < 10.0:
					printerr("Skill stopped emitting too early! Time: ", elapsed)

			# Monitor FPS
			var fps = Engine.get_frames_per_second()
			if fps < 30:
				printerr("Low FPS detected: ", fps)
				# The script itself handles reduction, we just log here.

	if elapsed >= 11.0:
		print("Test finished. Cleaning up.")
		get_tree().quit()

@tool
extends EditorScript

func _run():
	print("Starting animation generation...")
	var scene_path = "res://src/Scenes/Game/Spine/template.tscn"
	var packed_scene = load(scene_path)
	if not packed_scene:
		print("Error: Could not load scene at ", scene_path)
		return

	var root = packed_scene.instantiate()

	# Ensure AnimationPlayer
	var anim_player = root.get_node_or_null("AnimationPlayer")
	if not anim_player:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		root.add_child(anim_player)
		anim_player.owner = root
		print("Created AnimationPlayer")
	else:
		print("AnimationPlayer already exists")

	# Get Bones
	var skeleton = root.get_node("VisualRoot/Skeleton2D")
	var torso = skeleton.get_node("Torso")
	var arm_l = torso.get_node("ArmL")
	var arm_r = torso.get_node("ArmR")
	var leg_l = torso.get_node("LegL")
	var leg_r = torso.get_node("LegR")

	var bones = {
		"Torso": torso,
		"ArmL": arm_l,
		"ArmR": arm_r,
		"LegL": leg_l,
		"LegR": leg_r
	}

	# Calculate paths relative to root (AnimationPlayer's parent)
	var bone_paths = {}
	for name in bones:
		bone_paths[name] = root.get_path_to(bones[name])

	# Setup AnimationLibrary
	var library = anim_player.get_animation_library("")
	if not library:
		library = AnimationLibrary.new()
		anim_player.add_animation_library("", library)
		print("Created AnimationLibrary")

	# Helper to clean and create animation
	var create_anim = func(anim_name: String, length: float, loop: bool):
		if library.has_animation(anim_name):
			library.remove_animation(anim_name)
		var anim = Animation.new()
		anim.length = length
		if loop:
			anim.loop_mode = Animation.LOOP_LINEAR
		else:
			anim.loop_mode = Animation.LOOP_NONE
		library.add_animation(anim_name, anim)
		return anim

	# 1. RESET
	var anim_reset = create_anim.call("RESET", 0.001, false)
	for name in bones:
		var node = bones[name]
		var path = bone_paths[name]

		var track_pos = anim_reset.add_track(Animation.TYPE_VALUE)
		anim_reset.track_set_path(track_pos, str(path) + ":position")
		anim_reset.track_insert_key(track_pos, 0.0, node.position)

		var track_rot = anim_reset.add_track(Animation.TYPE_VALUE)
		anim_reset.track_set_path(track_rot, str(path) + ":rotation")
		anim_reset.track_insert_key(track_rot, 0.0, node.rotation)
	print("Created RESET animation")

	# 2. Idle (Loop, 1.0s, Torso move up)
	var anim_idle = create_anim.call("Idle", 1.0, true)
	var torso_path = bone_paths["Torso"]
	var torso_pos = bones["Torso"].position
	var track_idle = anim_idle.add_track(Animation.TYPE_VALUE)
	anim_idle.track_set_path(track_idle, str(torso_path) + ":position")
	anim_idle.track_insert_key(track_idle, 0.0, torso_pos)
	anim_idle.track_insert_key(track_idle, 0.5, torso_pos + Vector2(0, -2))
	anim_idle.track_insert_key(track_idle, 1.0, torso_pos)
	print("Created Idle animation")

	# 3. Walk (Loop, 0.4s, Legs rotate)
	var anim_walk = create_anim.call("Walk", 0.4, true)
	var leg_l_path = bone_paths["LegL"]
	var leg_r_path = bone_paths["LegR"]

	var track_walk_l = anim_walk.add_track(Animation.TYPE_VALUE)
	anim_walk.track_set_path(track_walk_l, str(leg_l_path) + ":rotation")
	anim_walk.track_insert_key(track_walk_l, 0.0, deg_to_rad(30))
	anim_walk.track_insert_key(track_walk_l, 0.2, deg_to_rad(-30))
	anim_walk.track_insert_key(track_walk_l, 0.4, deg_to_rad(30))

	var track_walk_r = anim_walk.add_track(Animation.TYPE_VALUE)
	anim_walk.track_set_path(track_walk_r, str(leg_r_path) + ":rotation")
	anim_walk.track_insert_key(track_walk_r, 0.0, deg_to_rad(-30))
	anim_walk.track_insert_key(track_walk_r, 0.2, deg_to_rad(30))
	anim_walk.track_insert_key(track_walk_r, 0.4, deg_to_rad(-30))
	print("Created Walk animation")

	# 4. Attack (No Loop, 0.3s, ArmR rotate)
	var anim_attack = create_anim.call("Attack", 0.3, false)
	var arm_r_path = bone_paths["ArmR"]
	var track_attack = anim_attack.add_track(Animation.TYPE_VALUE)
	anim_attack.track_set_path(track_attack, str(arm_r_path) + ":rotation")
	anim_attack.track_insert_key(track_attack, 0.0, deg_to_rad(0))
	anim_attack.track_insert_key(track_attack, 0.1, deg_to_rad(100))
	anim_attack.track_insert_key(track_attack, 0.3, deg_to_rad(0))
	print("Created Attack animation")

	# 5. Death (No Loop, 0.5s, Torso fall and rotate)
	var anim_death = create_anim.call("Death", 0.5, false)
	var track_death_pos = anim_death.add_track(Animation.TYPE_VALUE)
	anim_death.track_set_path(track_death_pos, str(torso_path) + ":position")
	anim_death.track_insert_key(track_death_pos, 0.0, torso_pos)
	anim_death.track_insert_key(track_death_pos, 0.5, torso_pos + Vector2(0, 50))

	var track_death_rot = anim_death.add_track(Animation.TYPE_VALUE)
	anim_death.track_set_path(track_death_rot, str(torso_path) + ":rotation")
	anim_death.track_insert_key(track_death_rot, 0.0, bones["Torso"].rotation)
	anim_death.track_insert_key(track_death_rot, 0.5, deg_to_rad(90))
	print("Created Death animation")

	# Save
	var new_packed = PackedScene.new()
	var pack_result = new_packed.pack(root)
	if pack_result == OK:
		var save_result = ResourceSaver.save(new_packed, scene_path)
		if save_result == OK:
			print("Scene saved successfully to ", scene_path)
		else:
			print("Error saving scene: ", save_result)
	else:
		print("Error packing scene: ", pack_result)

	root.queue_free()

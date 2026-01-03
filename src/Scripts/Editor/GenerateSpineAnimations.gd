@tool
extends EditorScript

func _run():
	var scene_path = "res://src/Scenes/Game/Spine/template.tscn"
	var scene = load(scene_path)
	if not scene:
		printerr("Failed to load scene: " + scene_path)
		return

	var root = scene.instantiate()

	# Ensure AnimationPlayer exists
	var anim_player = root.get_node_or_null("AnimationPlayer")
	if not anim_player:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		root.add_child(anim_player)
		anim_player.owner = root

	# Get or create AnimationLibrary
	var library_name = ""
	var library = anim_player.get_animation_library(library_name)
	if not library:
		library = AnimationLibrary.new()
		anim_player.add_animation_library(library_name, library)

	# Bone Paths relative to root (Template)
	var base_path = "VisualRoot/Skeleton2D/"
	var bone_paths = {
		"Torso": base_path + "Torso",
		"ArmL": base_path + "Torso/ArmL",
		"ArmR": base_path + "Torso/ArmR",
		"LegL": base_path + "Torso/LegL",
		"LegR": base_path + "Torso/LegR"
	}

	# Get Bone nodes to access rest values
	var bones = {}
	for key in bone_paths:
		var node = root.get_node_or_null(bone_paths[key])
		if not node:
			printerr("Bone not found: " + key + " at " + bone_paths[key])
			return
		bones[key] = node

	# --- RESET Animation ---
	var anim_reset = Animation.new()
	anim_reset.length = 0.001 # Standard short length for RESET
	anim_reset.loop_mode = Animation.LOOP_NONE
	for key in bones:
		var b = bones[key]
		var path = bone_paths[key]
		# Position
		add_track(anim_reset, path, "position", [{ "time": 0.0, "value": b.rest.origin }])
		# Rotation
		add_track(anim_reset, path, "rotation", [{ "time": 0.0, "value": b.rest.get_rotation() }])

	add_or_replace_animation(library, "RESET", anim_reset)

	# --- Idle Animation ---
	var anim_idle = Animation.new()
	anim_idle.length = 1.0
	anim_idle.loop_mode = Animation.LOOP_LINEAR

	var torso_rest_pos = bones["Torso"].rest.origin
	# 0.0s: y=0 (relative to rest? No, absolute. rest.y is 0)
	# 0.5s: y=-2
	# 1.0s: y=0
	var idle_keys = [
		{ "time": 0.0, "value": torso_rest_pos },
		{ "time": 0.5, "value": torso_rest_pos + Vector2(0, -2) },
		{ "time": 1.0, "value": torso_rest_pos }
	]
	add_track(anim_idle, bone_paths["Torso"], "position", idle_keys)

	add_or_replace_animation(library, "Idle", anim_idle)

	# --- Walk Animation ---
	var anim_walk = Animation.new()
	anim_walk.length = 0.4
	anim_walk.loop_mode = Animation.LOOP_LINEAR

	var legl_rest_rot = bones["LegL"].rest.get_rotation()
	var legr_rest_rot = bones["LegR"].rest.get_rotation()

	# LegL: +30, -30, +30
	var legl_keys = [
		{ "time": 0.0, "value": legl_rest_rot + deg_to_rad(30) },
		{ "time": 0.2, "value": legl_rest_rot + deg_to_rad(-30) },
		{ "time": 0.4, "value": legl_rest_rot + deg_to_rad(30) }
	]
	add_track(anim_walk, bone_paths["LegL"], "rotation", legl_keys)

	# LegR: -30, +30, -30
	var legr_keys = [
		{ "time": 0.0, "value": legr_rest_rot + deg_to_rad(-30) },
		{ "time": 0.2, "value": legr_rest_rot + deg_to_rad(30) },
		{ "time": 0.4, "value": legr_rest_rot + deg_to_rad(-30) }
	]
	add_track(anim_walk, bone_paths["LegR"], "rotation", legr_keys)

	add_or_replace_animation(library, "Walk", anim_walk)

	# --- Attack Animation ---
	var anim_attack = Animation.new()
	anim_attack.length = 0.3
	anim_attack.loop_mode = Animation.LOOP_NONE

	var armr_rest_rot = bones["ArmR"].rest.get_rotation()

	# ArmR: 0, 100, 0 (deg)
	var armr_keys = [
		{ "time": 0.0, "value": armr_rest_rot + deg_to_rad(0) },
		{ "time": 0.1, "value": armr_rest_rot + deg_to_rad(100) },
		{ "time": 0.3, "value": armr_rest_rot + deg_to_rad(0) }
	]
	add_track(anim_attack, bone_paths["ArmR"], "rotation", armr_keys)

	add_or_replace_animation(library, "Attack", anim_attack)

	# --- Death Animation ---
	var anim_death = Animation.new()
	anim_death.length = 0.5
	anim_death.loop_mode = Animation.LOOP_NONE

	var torso_rest_rot = bones["Torso"].rest.get_rotation()

	# Torso:
	# 0.0: Normal
	# 0.5: pos.y += 50, rot = 90 deg

	var death_pos_keys = [
		{ "time": 0.0, "value": torso_rest_pos },
		{ "time": 0.5, "value": torso_rest_pos + Vector2(0, 50) }
	]
	add_track(anim_death, bone_paths["Torso"], "position", death_pos_keys)

	var death_rot_keys = [
		{ "time": 0.0, "value": torso_rest_rot },
		{ "time": 0.5, "value": torso_rest_rot + deg_to_rad(90) }
	]
	add_track(anim_death, bone_paths["Torso"], "rotation", death_rot_keys)

	add_or_replace_animation(library, "Death", anim_death)

	# --- Save ---
	var packed = PackedScene.new()
	var result = packed.pack(root)
	if result == OK:
		var error = ResourceSaver.save(packed, scene_path)
		if error == OK:
			print("Successfully saved animations to " + scene_path)
		else:
			printerr("Error saving scene: " + str(error))
	else:
		printerr("Error packing scene: " + str(result))

	root.queue_free() # Clean up

func add_track(anim: Animation, path: String, property: String, keys: Array):
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, path + ":" + property)
	for key in keys:
		anim.track_insert_key(track_idx, key.time, key.value)

func add_or_replace_animation(library: AnimationLibrary, name: String, anim: Animation):
	if library.has_animation(name):
		library.remove_animation(name)
	library.add_animation(name, anim)

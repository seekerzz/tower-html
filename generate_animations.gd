@tool
extends SceneTree

func _init():
    var path = "src/Scenes/Game/Spine/template.tscn"
    print("Loading scene from: " + path)
    var packed_scene = load(path)
    if not packed_scene:
        print("Error: Could not load scene.")
        quit()
        return

    var root = packed_scene.instantiate()

    # Add AnimationPlayer
    var anim_player = root.get_node_or_null("AnimationPlayer")
    if not anim_player:
        print("Creating AnimationPlayer...")
        anim_player = AnimationPlayer.new()
        anim_player.name = "AnimationPlayer"
        root.add_child(anim_player)
        anim_player.owner = root
    else:
        print("AnimationPlayer already exists.")

    # Ensure AnimationLibrary exists
    var library = null
    if anim_player.has_animation_library(""):
        library = anim_player.get_animation_library("")
    else:
        library = AnimationLibrary.new()
        anim_player.add_animation_library("", library)

    # Node paths setup
    var skel_path = "VisualRoot/Skeleton2D"
    var torso_rel = "Torso"

    # Map bone names to nodes
    var bone_nodes = {}

    var torso_node = root.get_node(skel_path + "/" + torso_rel)
    bone_nodes["Torso"] = torso_node

    for b in ["ArmL", "ArmR", "LegL", "LegR"]:
        bone_nodes[b] = torso_node.get_node(b)

    # Get paths relative to root for tracks
    var bone_paths = {}
    for b in bone_nodes:
        bone_paths[b] = str(root.get_path_to(bone_nodes[b]))
        print("Path for " + b + ": " + bone_paths[b])

    # Capture initial state
    var defaults = {}
    for b in bone_nodes:
        defaults[b] = {
            "pos": bone_nodes[b].position,
            "rot": bone_nodes[b].rotation
        }

    # Helper to add track
    var add_track = func(anim: Animation, bone: String, property: String, times: Array, values: Array):
        var track_idx = anim.add_track(Animation.TYPE_VALUE)
        var full_path = bone_paths[bone] + ":" + property
        anim.track_set_path(track_idx, full_path)
        for i in range(len(times)):
            anim.track_insert_key(track_idx, times[i], values[i])

    # --- RESET ---
    print("Generating RESET...")
    if library.has_animation("RESET"):
        library.remove_animation("RESET") # Replace existing
    var anim_reset = Animation.new()
    anim_reset.length = 0.001
    for b in bone_nodes:
        add_track.call(anim_reset, b, "position", [0.0], [defaults[b].pos])
        add_track.call(anim_reset, b, "rotation", [0.0], [defaults[b].rot])
    library.add_animation("RESET", anim_reset)

    # --- Idle ---
    print("Generating Idle...")
    if library.has_animation("Idle"):
        library.remove_animation("Idle")
    var anim_idle = Animation.new()
    anim_idle.loop_mode = Animation.LOOP_LINEAR
    anim_idle.length = 1.6

    # Torso: Breathe (Y axis)
    var t_base = defaults["Torso"].pos
    # Y-axis adjustment: Torso moves slightly
    add_track.call(anim_idle, "Torso", "position", [0.0, 0.8, 1.6], [t_base, t_base + Vector2(0, 2), t_base])

    # Arms: Light rotation
    for arm in ["ArmL", "ArmR"]:
        var rot_base = defaults[arm].rot
        var offset = 0.08 # ~5 degrees
        var dir = 1 if arm == "ArmL" else -1
        # Loop: base -> base+offset -> base
        add_track.call(anim_idle, arm, "rotation", [0.0, 0.8, 1.6], [rot_base, rot_base + (offset * dir), rot_base])

    library.add_animation("Idle", anim_idle)

    # --- Walk ---
    print("Generating Walk...")
    if library.has_animation("Walk"):
        library.remove_animation("Walk")
    var anim_walk = Animation.new()
    anim_walk.loop_mode = Animation.LOOP_LINEAR
    anim_walk.length = 0.8

    # Legs: Swing (Opposite)
    var leg_swing = 0.5 # radians

    # LegL
    add_track.call(anim_walk, "LegL", "rotation", [0.0, 0.2, 0.4, 0.6, 0.8],
        [defaults["LegL"].rot + leg_swing, defaults["LegL"].rot, defaults["LegL"].rot - leg_swing, defaults["LegL"].rot, defaults["LegL"].rot + leg_swing])

    # LegR
    add_track.call(anim_walk, "LegR", "rotation", [0.0, 0.2, 0.4, 0.6, 0.8],
        [defaults["LegR"].rot - leg_swing, defaults["LegR"].rot, defaults["LegR"].rot + leg_swing, defaults["LegR"].rot, defaults["LegR"].rot - leg_swing])

    # Arms: Opposite to legs
    var arm_swing = 0.4
    # ArmL matches LegR pattern (Back -> Front)
    add_track.call(anim_walk, "ArmL", "rotation", [0.0, 0.2, 0.4, 0.6, 0.8],
        [defaults["ArmL"].rot - arm_swing, defaults["ArmL"].rot, defaults["ArmL"].rot + arm_swing, defaults["ArmL"].rot, defaults["ArmL"].rot - arm_swing])

    # ArmR matches LegL pattern (Front -> Back)
    add_track.call(anim_walk, "ArmR", "rotation", [0.0, 0.2, 0.4, 0.6, 0.8],
        [defaults["ArmR"].rot + arm_swing, defaults["ArmR"].rot, defaults["ArmR"].rot - arm_swing, defaults["ArmR"].rot, defaults["ArmR"].rot + arm_swing])

    # Torso: Bob (Up Down)
    var t_bob = Vector2(0, -5)
    add_track.call(anim_walk, "Torso", "position", [0.0, 0.2, 0.4, 0.6, 0.8],
        [t_base, t_base + t_bob, t_base, t_base + t_bob, t_base])

    library.add_animation("Walk", anim_walk)

    # --- Attack ---
    print("Generating Attack...")
    if library.has_animation("Attack"):
        library.remove_animation("Attack")
    var anim_attack = Animation.new()
    anim_attack.length = 0.6
    anim_attack.loop_mode = Animation.LOOP_NONE

    # Torso Windup
    add_track.call(anim_attack, "Torso", "rotation", [0.0, 0.2, 0.3, 0.6],
        [defaults["Torso"].rot, defaults["Torso"].rot - 0.2, defaults["Torso"].rot + 0.1, defaults["Torso"].rot])

    # ArmR (Attack arm)
    # 0.0-0.2: Back
    # 0.2-0.3: Strike Forward
    # 0.3-0.6: Return
    add_track.call(anim_attack, "ArmR", "rotation", [0.0, 0.2, 0.3, 0.6],
        [defaults["ArmR"].rot, defaults["ArmR"].rot - 1.0, defaults["ArmR"].rot + 1.5, defaults["ArmR"].rot])

    library.add_animation("Attack", anim_attack)

    # --- Death ---
    print("Generating Death...")
    if library.has_animation("Death"):
        library.remove_animation("Death")
    var anim_death = Animation.new()
    anim_death.length = 1.0
    anim_death.loop_mode = Animation.LOOP_NONE

    # Torso: Drop and Rotate
    # Move Y down (positive)
    var drop_y = 60.0 # Just an estimation to look like hitting ground
    add_track.call(anim_death, "Torso", "position", [0.0, 1.0], [t_base, t_base + Vector2(0, drop_y)])
    add_track.call(anim_death, "Torso", "rotation", [0.0, 1.0], [defaults["Torso"].rot, defaults["Torso"].rot + PI/2])

    # Limbs splay
    add_track.call(anim_death, "ArmL", "rotation", [0.0, 1.0], [defaults["ArmL"].rot, defaults["ArmL"].rot - 1.5])
    add_track.call(anim_death, "ArmR", "rotation", [0.0, 1.0], [defaults["ArmR"].rot, defaults["ArmR"].rot - 1.5])
    add_track.call(anim_death, "LegL", "rotation", [0.0, 1.0], [defaults["LegL"].rot, defaults["LegL"].rot + 0.5])
    add_track.call(anim_death, "LegR", "rotation", [0.0, 1.0], [defaults["LegR"].rot, defaults["LegR"].rot + 0.5])

    library.add_animation("Death", anim_death)

    # Save
    print("Saving scene...")
    var packed = PackedScene.new()
    var result = packed.pack(root)
    if result == OK:
        var err = ResourceSaver.save(packed, path)
        if err == OK:
            print("Successfully saved to " + path)
        else:
            print("Error saving resource: " + str(err))
    else:
        print("Error packing scene: " + str(result))

    quit()

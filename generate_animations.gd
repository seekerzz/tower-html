@tool
extends SceneTree

func _init():
    process()
    quit()

func process():
    var scene_path = "src/Scenes/Game/Spine/template.tscn"
    if not FileAccess.file_exists(scene_path):
        print("Error: File not found: ", scene_path)
        return

    # Load the scene
    var packed_scene = load(scene_path)
    if not packed_scene:
        print("Error: Failed to load scene.")
        return

    # Instantiate
    var root = packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
    if not root:
        print("Error: Failed to instantiate scene.")
        return

    print("Instantiated root: ", root.name)

    # 1. Add AnimationPlayer
    var anim_player = root.get_node_or_null("AnimationPlayer")
    if not anim_player:
        anim_player = AnimationPlayer.new()
        anim_player.name = "AnimationPlayer"
        root.add_child(anim_player)
        anim_player.owner = root
        print("Added AnimationPlayer")
    else:
        print("AnimationPlayer already exists")

    # Ensure AnimationLibrary
    var library = null
    var library_name = ""
    if anim_player.has_animation_library(library_name):
        library = anim_player.get_animation_library(library_name)
    else:
        library = AnimationLibrary.new()
        anim_player.add_animation_library(library_name, library)

    # 2. Get Bone Nodes and Initial Transforms
    var bone_paths = {
        "Torso": "VisualRoot/Skeleton2D/Torso",
        "ArmL": "VisualRoot/Skeleton2D/Torso/ArmL",
        "ArmR": "VisualRoot/Skeleton2D/Torso/ArmR",
        "LegL": "VisualRoot/Skeleton2D/Torso/LegL",
        "LegR": "VisualRoot/Skeleton2D/Torso/LegR"
    }

    var bones = {}
    var initial_transforms = {}

    for key in bone_paths:
        var path = bone_paths[key]
        var node = root.get_node_or_null(path)
        if not node:
            print("Error: Node not found: ", path)
            return
        bones[key] = node
        initial_transforms[key] = {
            "pos": node.position,
            "rot": node.rotation
        }

    # Generate Animations
    create_reset(library, bone_paths, initial_transforms)
    create_idle(library, bone_paths, initial_transforms)
    create_walk(library, bone_paths, initial_transforms)
    create_attack(library, bone_paths, initial_transforms)
    create_death(library, bone_paths, initial_transforms)

    # 3. Save
    # Ensure ownership
    recursive_set_owner(root, root)

    var new_packed = PackedScene.new()
    var err = new_packed.pack(root)
    if err != OK:
        print("Error packing scene: ", err)
        return

    err = ResourceSaver.save(new_packed, scene_path)
    if err != OK:
        print("Error saving scene: ", err)
    else:
        print("Scene saved successfully.")

func recursive_set_owner(node, root):
    if node != root:
        node.owner = root
    for child in node.get_children():
        recursive_set_owner(child, root)

func create_anim(library: AnimationLibrary, name: String, length: float, loop: bool) -> Animation:
    var anim = Animation.new()
    anim.length = length
    if loop:
        anim.loop_mode = Animation.LOOP_LINEAR
    else:
        anim.loop_mode = Animation.LOOP_NONE

    if library.has_animation(name):
        library.remove_animation(name)
    library.add_animation(name, anim)
    return anim

func add_track(anim: Animation, node_path: String, property: String, keys: Array):
    var track_idx = anim.add_track(Animation.TYPE_VALUE)
    anim.track_set_path(track_idx, node_path + ":" + property)
    for k in keys:
        var trans = 1.0
        anim.track_insert_key(track_idx, k.time, k.val, trans)

func create_reset(lib, paths, inits):
    var anim = create_anim(lib, "RESET", 0.001, false)
    for b in paths:
        var p = paths[b]
        var i = inits[b]
        add_track(anim, p, "position", [{"time": 0.0, "val": i.pos}])
        add_track(anim, p, "rotation", [{"time": 0.0, "val": i.rot}])

func create_idle(lib, paths, inits):
    var anim = create_anim(lib, "Idle", 1.6, true)
    var t = inits["Torso"]
    # Torso Y: 0.0 -> +2 (Down) -> 0.0
    add_track(anim, paths["Torso"], "position", [
        {"time": 0.0, "val": t.pos},
        {"time": 0.8, "val": t.pos + Vector2(0, 2)},
        {"time": 1.6, "val": t.pos}
    ])

    var al = inits["ArmL"]
    add_track(anim, paths["ArmL"], "rotation", [
        {"time": 0.0, "val": al.rot},
        {"time": 0.8, "val": al.rot + deg_to_rad(5)},
        {"time": 1.6, "val": al.rot}
    ])
    var ar = inits["ArmR"]
    add_track(anim, paths["ArmR"], "rotation", [
        {"time": 0.0, "val": ar.rot},
        {"time": 0.8, "val": ar.rot - deg_to_rad(5)},
        {"time": 1.6, "val": ar.rot}
    ])

func create_walk(lib, paths, inits):
    var anim = create_anim(lib, "Walk", 0.8, true)

    var ll = inits["LegL"]
    var lr = inits["LegR"]
    var swing = deg_to_rad(30)

    add_track(anim, paths["LegL"], "rotation", [
        {"time": 0.0, "val": ll.rot + swing},
        {"time": 0.4, "val": ll.rot - swing},
        {"time": 0.8, "val": ll.rot + swing}
    ])
    add_track(anim, paths["LegR"], "rotation", [
        {"time": 0.0, "val": lr.rot - swing},
        {"time": 0.4, "val": lr.rot + swing},
        {"time": 0.8, "val": lr.rot - swing}
    ])

    var t = inits["Torso"]
    add_track(anim, paths["Torso"], "position", [
        {"time": 0.0, "val": t.pos},
        {"time": 0.2, "val": t.pos + Vector2(0, -5)}, # Up
        {"time": 0.4, "val": t.pos},
        {"time": 0.6, "val": t.pos + Vector2(0, -5)}, # Up
        {"time": 0.8, "val": t.pos}
    ])

    var al = inits["ArmL"]
    var ar = inits["ArmR"]
    var arm_swing = deg_to_rad(20)

    add_track(anim, paths["ArmL"], "rotation", [
        {"time": 0.0, "val": al.rot - arm_swing},
        {"time": 0.4, "val": al.rot + arm_swing},
        {"time": 0.8, "val": al.rot - arm_swing}
    ])
    add_track(anim, paths["ArmR"], "rotation", [
        {"time": 0.0, "val": ar.rot + arm_swing},
        {"time": 0.4, "val": ar.rot - arm_swing},
        {"time": 0.8, "val": ar.rot + arm_swing}
    ])

func create_attack(lib, paths, inits):
    var anim = create_anim(lib, "Attack", 0.6, false)

    var t = inits["Torso"]
    add_track(anim, paths["Torso"], "rotation", [
        {"time": 0.0, "val": t.rot},
        {"time": 0.2, "val": t.rot - deg_to_rad(10)},
        {"time": 0.3, "val": t.rot + deg_to_rad(15)},
        {"time": 0.6, "val": t.rot}
    ])

    var ar = inits["ArmR"]
    var atk_swing = deg_to_rad(60)
    add_track(anim, paths["ArmR"], "rotation", [
        {"time": 0.0, "val": ar.rot},
        {"time": 0.2, "val": ar.rot - atk_swing},
        {"time": 0.3, "val": ar.rot + atk_swing},
        {"time": 0.6, "val": ar.rot}
    ])

    var al = inits["ArmL"]
    add_track(anim, paths["ArmL"], "rotation", [
        {"time": 0.0, "val": al.rot},
        {"time": 0.2, "val": al.rot + deg_to_rad(20)},
        {"time": 0.3, "val": al.rot - deg_to_rad(20)},
        {"time": 0.6, "val": al.rot}
    ])

func create_death(lib, paths, inits):
    var anim = create_anim(lib, "Death", 1.0, false)

    var t = inits["Torso"]
    add_track(anim, paths["Torso"], "position", [
        {"time": 0.0, "val": t.pos},
        {"time": 1.0, "val": t.pos + Vector2(0, 100)}
    ])
    add_track(anim, paths["Torso"], "rotation", [
        {"time": 0.0, "val": t.rot},
        {"time": 1.0, "val": t.rot + deg_to_rad(90)}
    ])

    var al = inits["ArmL"]
    add_track(anim, paths["ArmL"], "rotation", [
        {"time": 0.0, "val": al.rot},
        {"time": 1.0, "val": al.rot - deg_to_rad(90)}
    ])
    var ar = inits["ArmR"]
    add_track(anim, paths["ArmR"], "rotation", [
        {"time": 0.0, "val": ar.rot},
        {"time": 1.0, "val": ar.rot + deg_to_rad(90)}
    ])
    var ll = inits["LegL"]
    add_track(anim, paths["LegL"], "rotation", [
        {"time": 0.0, "val": ll.rot},
        {"time": 1.0, "val": ll.rot + deg_to_rad(20)}
    ])
    var lr = inits["LegR"]
    add_track(anim, paths["LegR"], "rotation", [
        {"time": 0.0, "val": lr.rot},
        {"time": 1.0, "val": lr.rot - deg_to_rad(20)}
    ])

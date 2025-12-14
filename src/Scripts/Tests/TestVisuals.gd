extends SceneTree

func _init():
    print("Starting visual verification...")
    test_visuals()
    print("Visual verification complete.")
    quit()

func test_visuals():
    # 1. MainGame Background
    var main_game_scene = load("res://src/Scenes/Game/MainGame.tscn").instantiate()
    var bg = main_game_scene.get_node("Background")
    if bg and bg is TextureRect and bg.texture != null:
        print("PASS: MainGame Background exists and has texture.")
    else:
        print("FAIL: MainGame Background missing or invalid.")

    # 2. Shop Background
    var shop_scene = load("res://src/Scenes/UI/Shop.tscn").instantiate()
    var shop_bg = shop_scene.get_node("Panel/Background")
    if shop_bg and shop_bg is TextureRect and shop_bg.texture != null:
        print("PASS: Shop Background exists and has texture.")
    else:
        print("FAIL: Shop Background missing or invalid.")

    # 3. Tile Setup and Randomness
    var tile_scene = load("res://src/Scenes/Game/Tile.tscn")
    var tile1 = tile_scene.instantiate()
    var tile2 = tile_scene.instantiate()

    # Simulate setup
    tile1.setup(0, 0, "normal")
    tile2.setup(1, 0, "normal")

    # Check structure
    var sprite1 = tile1.get_node("BaseSprite")
    var grid1 = tile1.get_node("GridBorder")

    if sprite1 and grid1:
        print("PASS: Tile nodes BaseSprite and GridBorder exist.")
    else:
        print("FAIL: Tile nodes missing.")

    if sprite1.hframes == 5 and sprite1.vframes == 5:
        print("PASS: BaseSprite has correct hframes/vframes.")
    else:
        print("FAIL: BaseSprite frames incorrect.")

    if grid1.visible == false:
        print("PASS: GridBorder is hidden by default.")
    else:
        print("FAIL: GridBorder is visible by default.")

    # Check Randomness (this might fail occasionally if rand is same, but 1/25 chance)
    # We'll try a few times if they match
    var diff_found = false
    if tile1._random_frame != tile2._random_frame:
        diff_found = true
    else:
        # Try one more
        var tile3 = tile_scene.instantiate()
        tile3.setup(2, 0, "normal")
        if tile3._random_frame != tile1._random_frame:
            diff_found = true

    if diff_found:
        print("PASS: Tile randomness verified (frames differ).")
    else:
        print("WARNING: Tile randomness check inconclusive (same frames generated).")

    # 4. Grid Visibility Toggle
    tile1.set_grid_visible(true)
    if grid1.visible == true:
        print("PASS: set_grid_visible(true) works.")
    else:
        print("FAIL: set_grid_visible(true) failed.")

    tile1.set_grid_visible(false)
    if grid1.visible == false:
        print("PASS: set_grid_visible(false) works.")
    else:
        print("FAIL: set_grid_visible(false) failed.")

    # Cleanup
    tile1.free()
    tile2.free()
    main_game_scene.free()
    shop_scene.free()

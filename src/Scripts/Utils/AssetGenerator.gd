extends Node

static func ensure_assets_exist():
    var dir = DirAccess.open("res://")
    if not dir.dir_exists("src/assets/images/UI"):
        dir.make_dir_recursive("src/assets/images/UI")

    # 1. Tile Sheet
    if not FileAccess.file_exists("res://src/assets/images/UI/tile_sheet.png"):
        var img = Image.create(300, 300, false, Image.FORMAT_RGBA8)
        img.fill(Color(0.2, 0.2, 0.2))
        for x in range(5):
            for y in range(5):
                var rect = Rect2i(x * 60, y * 60, 60, 60)
                var color = Color(0.3, 0.3, 0.3)
                color.r += randf() * 0.1
                img.fill_rect(rect, color)
                # Noise
                for i in range(20):
                    img.set_pixel(x*60 + randi()%60, y*60 + randi()%60, Color.GRAY)
        img.save_png("res://src/assets/images/UI/tile_sheet.png")

    # 2. Spawn
    if not FileAccess.file_exists("res://src/assets/images/UI/tile_spawn.png"):
        var img = Image.create(60, 60, false, Image.FORMAT_RGBA8)
        img.fill(Color(0.8, 0.2, 0.2))
        img.save_png("res://src/assets/images/UI/tile_spawn.png")

    # 3. BG Battle
    if not FileAccess.file_exists("res://src/assets/images/UI/bg_battle.png"):
        var img = Image.create(1280, 720, false, Image.FORMAT_RGBA8) # Scaled down for placeholder
        img.fill(Color(0.05, 0.05, 0.1))
        for i in range(500):
            img.set_pixel(randi()%1280, randi()%720, Color.WHITE)
        img.save_png("res://src/assets/images/UI/bg_battle.png")

    # 4. BG Shop
    if not FileAccess.file_exists("res://src/assets/images/UI/bg_shop.png"):
        var img = Image.create(1280, 300, false, Image.FORMAT_RGBA8)
        img.fill(Color(0.4, 0.25, 0.1))
        img.save_png("res://src/assets/images/UI/bg_shop.png")

static func get_tile_sheet() -> Texture2D:
    ensure_assets_exist()
    var img = Image.load_from_file("res://src/assets/images/UI/tile_sheet.png")
    return ImageTexture.create_from_image(img)

static func get_spawn_texture() -> Texture2D:
    ensure_assets_exist()
    var img = Image.load_from_file("res://src/assets/images/UI/tile_spawn.png")
    return ImageTexture.create_from_image(img)

static func get_bg_battle() -> Texture2D:
    ensure_assets_exist()
    var img = Image.load_from_file("res://src/assets/images/UI/bg_battle.png")
    return ImageTexture.create_from_image(img)

static func get_bg_shop() -> Texture2D:
    ensure_assets_exist()
    var img = Image.load_from_file("res://src/assets/images/UI/bg_shop.png")
    return ImageTexture.create_from_image(img)

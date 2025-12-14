extends Node

func _ready():
    print("Starting TestTrapGeneration...")

    # GridManager is normally initialized by GameManager or MainGame.
    # Since we are running in isolation, we need to set up GameManager's grid_manager reference manually.

    var grid_manager = load("res://src/Scripts/GridManager.gd").new()
    add_child(grid_manager)
    # GameManager is an autoload, so it should be available.
    GameManager.grid_manager = grid_manager
    # We need to manually call _ready because we just instanced it, but add_child calls _ready automatically in Godot 4?
    # Actually add_child triggers _ready.

    # GridManager._ready() calls create_initial_grid().

    # 2. Simulate Projectile hit
    var projectile_script = load("res://src/Scripts/Projectile.gd")
    var projectile = Node2D.new()
    projectile.set_script(projectile_script)
    add_child(projectile)

    # Setup Mock Source Unit
    var unit_script = load("res://src/Scripts/Unit.gd")
    var source_unit = Node2D.new()
    source_unit.set_script(unit_script)
    # Need to initialize unit_data to avoid errors if accessed
    source_unit.unit_data = {"trait": "poison", "lifesteal_percent": 0.0}
    source_unit.type_key = "viper" # Expect "poison" trap

    projectile.source_unit = source_unit
    projectile.type = "stinger"

    # Setup Mock Enemy
    var enemy_script = load("res://src/Scripts/Enemy.gd")
    var enemy = Area2D.new()
    enemy.name = "MockEnemy"
    enemy.add_to_group("enemies")
    enemy.global_position = Vector2(2 * 60, 2 * 60) # Grid (2, 2)
    # The enemy script might have logic in _ready that depends on other things.
    # We can try to attach it.
    enemy.set_script(enemy_script)

    # Enemy.gd usually requires setup or ready.
    # Let's hope it doesn't crash.
    add_child(enemy)

    # 3. Trigger Trap Generation
    print("Triggering projectile impact...")

    # Note: randf() < 0.25 is in Projectile.gd.
    # Unless we patch Projectile.gd, we rely on luck or need to patch it first.
    # The prompt asks us to patch it.
    # But for the FIRST run, it might fail or not generate.
    # Let's try to run it. If it fails, it confirms the need for fix (or just luck).

    projectile._on_area_2d_area_entered(enemy)

    # 4. Verify Trap
    var grid_pos = Vector2i(2, 2)
    var passed = false
    if grid_manager.obstacles.has(grid_pos):
        var obstacle = grid_manager.obstacles[grid_pos]
        # Obstacle name is "Obstacle_poison"
        if "poison" in obstacle.name:
             print("PASS: Trap generated successfully at ", grid_pos)
             passed = true
        else:
             print("FAIL: Obstacle found but name is ", obstacle.name)
    else:
        print("FAIL: No trap generated at ", grid_pos)
        print("Obstacles: ", grid_manager.obstacles.keys())

    # Cleanup
    projectile.queue_free()
    source_unit.queue_free()
    enemy.queue_free()
    grid_manager.queue_free()

    if passed:
        print("Test Result: PASS")
    else:
        print("Test Result: FAIL")

    quit()

func quit():
    get_tree().quit()

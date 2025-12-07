extends Node

const ENEMY_SCENE = preload("res://src/Scenes/Game/Enemy.tscn")
const PROJECTILE_SCENE = preload("res://src/Scenes/Game/Projectile.tscn")

var enemies_to_spawn: int = 0
var spawn_timer: float = 0.0

func _ready():
	GameManager.combat_manager = self
	GameManager.wave_started.connect(_on_wave_started)

func _process(delta):
	if !GameManager.is_wave_active: return

	if enemies_to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_enemy()
			spawn_timer = 0.5 # Spawn rate

	# Check for win condition
	if enemies_to_spawn <= 0 and get_tree().get_nodes_in_group("enemies").size() == 0:
		GameManager.end_wave()

	# Unit Logic (Iterate over grid units)
	if GameManager.grid_manager:
		for key in GameManager.grid_manager.tiles:
			var tile = GameManager.grid_manager.tiles[key]
			if tile.unit and tile.type != "core":
				process_unit_combat(tile.unit, tile, delta)

func _on_wave_started():
	var wave = GameManager.wave
	enemies_to_spawn = 20 + floor(wave * 6)

func spawn_enemy():
	var angle = randf() * PI * 2
	var distance = 600 # Offscreen
	var spawn_pos = GameManager.grid_manager.global_position + Vector2(cos(angle), sin(angle)) * distance

	var type_key = "slime" # Randomize later

	var enemy = ENEMY_SCENE.instantiate()
	enemy.setup(type_key, GameManager.wave)
	enemy.global_position = spawn_pos
	add_child(enemy)
	enemies_to_spawn -= 1

func process_unit_combat(unit, tile, delta):
	if unit.cooldown > 0: return

	# Find target
	var target = find_nearest_enemy(tile.global_position, unit.range_val)
	if target:
		# Attack
		unit.cooldown = unit.atk_speed

		if unit.unit_data.attackType == "melee":
			target.take_damage(unit.damage)
		else:
			spawn_projectile(unit, tile.global_position, target)

func find_nearest_enemy(pos: Vector2, range_val: float):
	var nearest = null
	var min_dist = range_val

	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist = pos.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = enemy

	return nearest

func spawn_projectile(source_unit, pos, target):
	var proj = PROJECTILE_SCENE.instantiate()
	proj.setup(pos, target, source_unit.damage, 400.0, source_unit.unit_data.proj)
	add_child(proj)

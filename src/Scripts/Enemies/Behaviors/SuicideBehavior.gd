extends "res://src/Scripts/Enemies/Behaviors/DefaultBehavior.gd"

var is_suicide: bool = false

func init(enemy_node: CharacterBody2D, data: Dictionary):
	super.init(enemy_node, data)
	is_suicide = data.get("is_suicide", false)

func physics_process(delta: float) -> bool:
	if is_suicide:
		check_suicide_collision()
		if not is_instance_valid(enemy): return true # Exploded

	return super.physics_process(delta)

func check_suicide_collision():
	if GameManager.grid_manager:
		var core_dist = enemy.global_position.distance_to(GameManager.grid_manager.global_position)
		if core_dist < 40.0:
			explode_suicide(null)

func explode_suicide(target_wall):
	GameManager.damage_core(data.dmg)
	GameManager.spawn_floating_text(enemy.global_position, "BOOM!", Color.RED)
	var effect = load("res://src/Scripts/Effects/SlashEffect.gd").new()
	enemy.get_parent().add_child(effect)
	effect.global_position = enemy.global_position
	effect.configure("cross", Color.ORANGE)
	effect.scale = Vector2(2, 2)
	effect.play()
	enemy.queue_free()

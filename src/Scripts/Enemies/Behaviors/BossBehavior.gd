extends "res://src/Scripts/Enemies/Behaviors/DefaultBehavior.gd"

var stationary_timer: float = 0.0
var boss_skill: String = ""
var skill_cd_timer: float = 0.0
var is_stationary: bool = false

func init(enemy_node: CharacterBody2D, data: Dictionary):
	super.init(enemy_node, data)

	stationary_timer = data.get("stationary_time", 0.0)
	boss_skill = data.get("boss_skill", "")

	if stationary_timer > 0.0:
		is_stationary = true

	# Boss Physics Properties
	enemy.knockback_resistance = 10.0
	enemy.mass = 5.0

	# Adjust shape if needed - usually handled by Enemy.gd generic shape setup using radius
	# but Enemy.gd had specific check for "boss" to set CircleShape.
	# We can assume Enemy.gd generic setup handles radius if we don't override.
	# Original code: if type_key == "boss" ... circle_shape.radius = enemy_data.radius
	# Else check shape == "rect".
	# If we leave generic shape setup in Enemy.gd, it should be fine.

func physics_process(delta: float) -> bool:
	if is_stationary:
		stationary_timer -= delta
		skill_cd_timer -= delta
		if stationary_timer <= 0:
			is_stationary = false
		else:
			if boss_skill != "" and skill_cd_timer <= 0:
				perform_boss_skill(boss_skill)
				skill_cd_timer = 2.0
			return true # Override movement/states

	return super.physics_process(delta)

func perform_boss_skill(skill_name: String):
	if skill_name == "summon":
		GameManager.spawn_floating_text(enemy.global_position, "Summon!", Color.PURPLE)
		for i in range(3):
			var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
			if GameManager.combat_manager:
				GameManager.combat_manager._spawn_enemy_at_pos(enemy.global_position + offset, "minion")
	elif skill_name == "shoot_enemy":
		GameManager.spawn_floating_text(enemy.global_position, "Fire!", Color.ORANGE)
		if GameManager.combat_manager:
			GameManager.combat_manager._spawn_enemy_at_pos(enemy.global_position, "bullet_entity")

class_name StoneBlock
extends StaticBody2D

var max_hp: float = 100
var current_hp: float = 100
var damage_to_enemies: float = 20
var damage_formula: String = "fixed"  # "fixed" or "max_hp_percent"
var damage_percent: float = 0.0

var affected_enemies: Dictionary = {}  # enemy_instance_id -> last_damage_time
const DAMAGE_COOLDOWN: float = 0.5

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

func _ready():
	current_hp = max_hp
	add_to_group("obstacles")
	add_to_group("stone_blocks")

	# 设置碰撞
	collision_layer = 8  # 障碍物层
	collision_mask = 2   # 与敌人碰撞

	# 视觉设置
	modulate = Color(0.5, 0.5, 0.5, 1.0)

func _process(delta):
	_check_enemy_collisions()
	_update_visual()

func _check_enemy_collisions():
	# 获取与石块重叠的敌人
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = collision.shape
	query.transform = global_transform
	query.collision_mask = 2  # 敌人层

	var results = space_state.intersect_shape(query)

	for result in results:
		var enemy = result.collider
		if enemy.is_in_group("enemies"):
			_damage_enemy(enemy)

func _damage_enemy(enemy):
	var now = Time.get_ticks_msec() / 1000.0
	var enemy_id = enemy.get_instance_id()

	# 检查冷却
	if affected_enemies.has(enemy_id):
		if now - affected_enemies[enemy_id] < DAMAGE_COOLDOWN:
			return

	affected_enemies[enemy_id] = now

	# 计算伤害
	var damage = damage_to_enemies
	if damage_formula == "max_hp_percent":
		damage = enemy.max_hp * damage_percent

	enemy.take_damage(damage, self)

	# 视觉反馈
	GameManager.spawn_floating_text(enemy.global_position, "-%d" % int(damage), Color.GRAY)

func take_damage(amount: float, source = null):
	current_hp -= amount

	# 受击闪烁
	modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		modulate = Color(0.5, 0.5, 0.5, 1.0)

	if current_hp <= 0:
		_break_stone()

func _break_stone():
	# 破碎特效
	_play_break_effect()

	# 清理
	queue_free()

func _play_break_effect():
	# Check if effect exists, otherwise skip
	if ResourceLoader.exists("res://src/Scenes/Effects/StoneBreakEffect.tscn"):
		var effect = load("res://src/Scenes/Effects/StoneBreakEffect.tscn").instantiate()
		effect.global_position = global_position
		get_tree().current_scene.add_child(effect)

func _update_visual():
	# 根据血量调整外观
	var hp_percent = current_hp / max_hp
	sprite.modulate = Color(0.5, 0.5, 0.5, hp_percent)

func get_description() -> String:
	var desc = "石化石块\n"
	desc += "阻挡敌人并对其造成伤害\n"
	desc += "HP: %d/%d" % [current_hp, max_hp]
	if damage_formula == "max_hp_percent":
		desc += "\n伤害: %.0f%% 敌人MaxHP" % (damage_percent * 100)
	else:
		desc += "\n伤害: %.0f" % damage_to_enemies
	return desc

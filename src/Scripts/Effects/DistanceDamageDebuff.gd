extends "res://src/Scripts/Effects/StatusEffect.gd"
class_name DistanceDamageDebuff

var tick_interval: float = 0.5
var tick_timer: float = 0.0

func setup(target: Node, source: Object, params: Dictionary):
	type_key = "distance_damage"
	super.setup(target, source, params)
	tick_interval = params.get("tick_interval", 0.5)

func apply(delta: float):
	super.apply(delta)

	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer -= tick_interval
		_apply_damage()

func _apply_damage():
	var enemy = get_parent()
	if not enemy or not is_instance_valid(enemy):
		return

	var dist_to_core = enemy.global_position.distance_to(Vector2.ZERO)
	var damage = dist_to_core * 0.08

	if enemy.has_method("take_damage"):
		enemy.take_damage(damage, source_unit, "magic")

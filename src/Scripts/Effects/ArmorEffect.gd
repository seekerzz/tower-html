extends "res://src/Scripts/Effects/StatusEffect.gd"

func setup(target: Node, source: Object, params: Dictionary):
	super.setup(target, source, params)
	type_key = "armor"

func get_damage_multiplier() -> float:
	# Each stack provides 10% damage reduction
	return max(0.1, 1.0 - (0.1 * stacks))

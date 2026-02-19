class_name LifestealManager
extends Node

@export var lifesteal_ratio: float = 0.4

func _ready():
	# Connect to GameManager.enemy_hit signal
	# Signal signature: enemy_hit(enemy, source, amount)
	GameManager.enemy_hit.connect(_on_damage_dealt)

func _on_damage_dealt(target, source, damage):
	if !is_instance_valid(target) or !is_instance_valid(source):
		return

	# Check if target is an Enemy and has bleed stacks
	if not "bleed_stacks" in target:
		return

	if target.bleed_stacks <= 0:
		return

	# Check if source is a Bat Totem unit
	if not _is_bat_totem_unit(source):
		return

	# Calculate lifesteal amount
	var lifesteal_amount = target.bleed_stacks * 1.5 * lifesteal_ratio

	# Cap lifesteal amount to 5% of max core health per hit
	var max_heal = GameManager.max_core_health * 0.05
	lifesteal_amount = min(lifesteal_amount, max_heal)

	if lifesteal_amount > 0:
		if GameManager.has_method("heal_core"):
			GameManager.heal_core(lifesteal_amount)
		else:
			GameManager.damage_core(-lifesteal_amount)

		_show_lifesteal_effect(target.global_position, lifesteal_amount)

func _is_bat_totem_unit(source: Node) -> bool:
	# Check if source is a Unit and has type_key
	if source.get("type_key"):
		return source.type_key in ["mosquito", "blood_mage", "vampire_bat"]
	return false

func _show_lifesteal_effect(pos: Vector2, amount: float):
	# Green floating text
	GameManager.spawn_floating_text(pos, "+" + str(int(amount)), Color.GREEN, Vector2.UP)

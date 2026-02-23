class_name LifestealManager
extends Node

signal lifesteal_occurred(source, amount)

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
		# Debug: print why lifesteal didn't trigger
		if source.get("type_key"):
			print("[LifestealManager] Damage dealt by ", source.type_key, ", but not a bat totem unit")
		return

	print("[LifestealManager] Bat unit ", source.type_key if source.get("type_key") else "unknown", " hit enemy with ", target.bleed_stacks, " bleed stacks")

	# Calculate lifesteal amount
	var multiplier = GameManager.get_global_buff("lifesteal_multiplier", 1.0)
	var lifesteal_amount = target.bleed_stacks * 1.5 * lifesteal_ratio * multiplier

	# Cap lifesteal amount to 5% of max core health per hit
	var max_heal = GameManager.max_core_health * 0.05
	lifesteal_amount = min(lifesteal_amount, max_heal)

	if lifesteal_amount > 0:
		if GameManager.has_method("heal_core"):
			GameManager.heal_core(lifesteal_amount)
		else:
			GameManager.damage_core(-lifesteal_amount)

		lifesteal_occurred.emit(source, lifesteal_amount)
		_show_lifesteal_effect(target.global_position, lifesteal_amount)
		print("[LifestealManager] Bleed stacks: ", target.bleed_stacks, ", Lifesteal: ", lifesteal_amount)

func _is_bat_totem_unit(source: Node) -> bool:
	# Check if source is a Unit and has type_key or faction
	if not is_instance_valid(source):
		return false

	# Check by type_key (Bat Totem unit IDs)
	if source.get("type_key"):
		var bat_unit_types = ["mosquito", "blood_mage", "vampire_bat", "plague_spreader", "blood_ancestor"]
		if source.type_key in bat_unit_types:
			return true

	# Check by faction (alternative way to identify)
	if source.get("unit_data") and source.unit_data.get("faction") == "bat_totem":
		return true

	return false

func _show_lifesteal_effect(pos: Vector2, amount: float):
	# Green floating text
	GameManager.spawn_floating_text(pos, "+" + str(int(amount)), Color.GREEN, Vector2.UP)

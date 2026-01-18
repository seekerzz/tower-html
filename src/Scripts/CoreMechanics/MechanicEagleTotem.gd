extends "res://src/Scripts/CoreMechanics/CoreMechanic.gd"

var echo_chance: float = 0.3
var echo_mult: float = 1.0

func _ready():
	if Constants.CORE_TYPES.has("eagle_totem"):
		var data = Constants.CORE_TYPES["eagle_totem"]
		echo_chance = data.get("crit_echo_chance", 0.3)
		echo_mult = data.get("crit_echo_mult", 1.0)

func on_projectile_crit(projectile, target):
	if randf() < echo_chance:
		if projectile.has_method("trigger_eagle_echo"):
			projectile.trigger_eagle_echo(target, echo_mult)

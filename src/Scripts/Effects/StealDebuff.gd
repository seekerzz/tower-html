extends "res://src/Scripts/Effects/StatusEffect.gd"

var stat_type: String
var amount: float
var applied_amount: float = 0.0

func setup(target, source, params):
	super.setup(target, source, params)
	type_key = "steal_debuff"
	stat_type = params.get("stat_type", "")
	amount = params.get("amount", 0.0)
	_apply()

func _apply():
	var host = get_parent()
	if not host: return
	match stat_type:
		"attack":
			if "damage_mult" in host:
				host.damage_mult -= amount
				applied_amount = amount
		"attack_speed":
			if "attack_speed_mult" in host:
				host.attack_speed_mult -= amount
				applied_amount = amount

func _remove():
	var host = get_parent()
	if not host or applied_amount == 0: return
	match stat_type:
		"attack":
			if "damage_mult" in host:
				host.damage_mult += applied_amount
		"attack_speed":
			if "attack_speed_mult" in host:
				host.attack_speed_mult += applied_amount
	applied_amount = 0

func _exit_tree():
	_remove()

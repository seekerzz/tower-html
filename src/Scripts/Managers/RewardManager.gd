extends Node

signal reward_added(id)
signal sacrifice_state_changed(is_active)

const REWARDS = {
	"combat_repair": {
		"icon": "res://src/Assets/Icons/repair.png", # Placeholder
		"name": "Combat Repair",
		"rarity": "common",
		"type": "stat",
		"desc": "Repairs 20% of Core Health",
		"unique": false
	},
	"war_bonds": {
		"icon": "res://src/Assets/Icons/gold.png", # Placeholder
		"name": "War Bonds",
		"rarity": "common",
		"type": "stat",
		"desc": "Grants 150 Gold",
		"unique": false
	},
	"biomass_armor": {
		"icon": "res://src/Assets/Icons/armor.png", # Placeholder
		"name": "Biomass Armor",
		"rarity": "rare",
		"type": "artifact",
		"desc": "Increases Max Core HP by 500",
		"unique": true
	},
	"focus_fire": {
		"icon": "res://src/Assets/Icons/damage.png", # Placeholder
		"name": "Focus Fire",
		"rarity": "common",
		"type": "stat",
		"desc": "Increases Damage by 10%",
		"unique": false
	},
	"sacrifice_protocol": {
		"icon": "res://src/Assets/Icons/skull.png", # Placeholder
		"name": "Sacrifice Protocol",
		"rarity": "epic",
		"type": "artifact",
		"desc": "Unlocks Sacrifice Ability",
		"unique": true
	},
	"scrap_recycling": {
		"icon": "res://src/Assets/Icons/recycle.png", # Placeholder
		"name": "Scrap Recycling",
		"rarity": "rare",
		"type": "artifact",
		"desc": "Gain 1 Gold per enemy kill",
		"unique": true
	},
	"rapid_expansion": {
		"icon": "res://src/Assets/Icons/expand.png", # Placeholder
		"name": "Rapid Expansion",
		"rarity": "rare",
		"type": "stat",
		"desc": "Resource Generation +10%",
		"unique": false
	},
	"ammo_improvement": {
		"icon": "res://src/Assets/Icons/ammo.png", # Placeholder
		"name": "Ammo Improvement",
		"rarity": "common",
		"type": "stat",
		"desc": "Increases Range by 10%",
		"unique": false
	}
}

var acquired_artifacts = []
var active_buffs = {}

# Sacrifice Protocol State
var is_sacrifice_active = false
var sacrifice_cooldown = 0.0
const SACRIFICE_COOLDOWN_TIME = 60.0

func _process(delta):
	if sacrifice_cooldown > 0:
		sacrifice_cooldown -= delta
		if sacrifice_cooldown <= 0:
			sacrifice_cooldown = 0
			# Cooldown finished

func get_random_rewards(count: int) -> Array:
	var pool = []
	for id in REWARDS:
		var data = REWARDS[id]
		# Filter unique artifacts already owned
		if data.unique and id in acquired_artifacts:
			continue
		pool.append(id)

	pool.shuffle()

	var result_ids = pool.slice(0, count)
	var result_data = []
	for id in result_ids:
		var data = REWARDS[id].duplicate()
		data["id"] = id
		result_data.append(data)

	return result_data

func add_reward(id: String):
	if not REWARDS.has(id):
		push_error("RewardManager: Unknown reward id " + id)
		return

	var data = REWARDS[id]

	if data.type == "stat":
		active_buffs[id] = active_buffs.get(id, 0) + 1
		_apply_immediate_effects(id)
	elif data.type == "artifact":
		if data.unique and id in acquired_artifacts:
			return
		acquired_artifacts.append(id)
		_apply_immediate_effects(id)

	reward_added.emit(id)

func _apply_immediate_effects(id: String):
	# Check if GameManager is available (it is an Autoload)
	if not Engine.is_editor_hint() and has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		match id:
			"combat_repair":
				if gm.has_method("damage_core"):
					var heal = gm.max_core_health * 0.2
					gm.damage_core(-heal)
			"war_bonds":
				if gm.has_method("add_gold"):
					gm.add_gold(150)
			"biomass_armor":
				gm.max_core_health += 500
				gm.core_health += 500
				gm.resource_changed.emit()
			"focus_fire":
				gm.damage_multiplier += 0.1
				gm.resource_changed.emit()
			"rapid_expansion":
				gm.base_food_rate *= 1.1
				gm.base_mana_rate *= 1.1
				gm.resource_changed.emit()
			"ammo_improvement":
				# Maybe global range modifier? GameManager doesn't seem to have it.
				# Just record it for now.
				pass

func activate_sacrifice():
	if not "sacrifice_protocol" in acquired_artifacts:
		return

	if sacrifice_cooldown > 0:
		return

	is_sacrifice_active = true
	sacrifice_cooldown = SACRIFICE_COOLDOWN_TIME
	sacrifice_state_changed.emit(true)

	# Logic for sacrifice would go here or be handled by other systems listening to signal

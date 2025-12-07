extends Node

const UNIT_TYPES = {
	"mouse": { "name": "Gatling Mouse", "icon": "🐭", "cost": 15, "size": Vector2i(1,1), "damage": 3, "range": 250, "atk_speed": 0.15, "food_cost": 1.5, "mana_cost": 0, "attack_type": "ranged", "proj": "dot", "desc": "Ranged: Super Fast" },
	"turtle": { "name": "Sniper Turtle", "icon": "🐢", "cost": 25, "size": Vector2i(1,1), "damage": 45, "range": 500, "atk_speed": 1.8, "food_cost": 8, "mana_cost": 0, "attack_type": "ranged", "proj": "rocket", "desc": "Ranged: Long Range Sniper" },
	"ranger": { "name": "Ranger", "icon": "🤠", "cost": 60, "size": Vector2i(1,1), "damage": 12, "range": 180, "atk_speed": 1.5, "food_cost": 3, "mana_cost": 0, "attack_type": "ranged", "proj": "pellet", "proj_count": 5, "spread": 0.5, "desc": "Shotgun: 5 pellets" },
	"ninja": { "name": "Ninja", "icon": "🥷", "cost": 80, "size": Vector2i(1,1), "damage": 25, "range": 250, "atk_speed": 0.8, "food_cost": 4, "mana_cost": 0, "attack_type": "ranged", "proj": "shuriken", "pierce": 3, "desc": "Pierce 3 enemies" },
	"tesla": { "name": "Tesla Coil", "icon": "⚡", "cost": 70, "size": Vector2i(1,1), "damage": 35, "range": 200, "atk_speed": 1.2, "food_cost": 5, "mana_cost": 5, "attack_type": "ranged", "proj": "lightning", "chain": 4, "desc": "Chain Lightning" },
	"cannon": { "name": "Cannon", "icon": "💣", "cost": 90, "size": Vector2i(1,1), "damage": 40, "range": 200, "atk_speed": 2.0, "food_cost": 8, "mana_cost": 0, "attack_type": "ranged", "proj": "swarm_wave", "desc": "Swarm Wave" },
	"void": { "name": "Singularity", "icon": "🌌", "cost": 200, "size": Vector2i(1,1), "damage": 5, "range": 300, "atk_speed": 3.0, "food_cost": 15, "mana_cost": 20, "attack_type": "ranged", "proj": "blackhole", "desc": "Blackhole" },
	"knight": { "name": "Berserker", "icon": "🗡️", "cost": 30, "size": Vector2i(1,1), "damage": 20, "range": 100, "atk_speed": 0.8, "food_cost": 4, "mana_cost": 0, "attack_type": "melee", "splash": 60, "skill": "rage", "skill_cd": 10, "desc": "Melee: Cleave" },
	"bear":   { "name": "Bear", "icon": "🐻", "cost": 65, "size": Vector2i(1,1), "damage": 35, "range": 80, "atk_speed": 1.2, "food_cost": 5, "mana_cost": 0, "attack_type": "melee", "skill": "stun", "skill_cd": 15, "desc": "Melee: Stun" },
	"treant": { "name": "Treant", "icon": "🌳", "cost": 40, "size": Vector2i(1,1), "damage": 10, "range": 80, "atk_speed": 1.5, "food_cost": 2, "mana_cost": 0, "attack_type": "melee", "desc": "Tank" },
	"wizard": { "name": "Wizard", "icon": "🧙‍♂️", "cost": 50, "size": Vector2i(1,1), "damage": 60, "range": 350, "atk_speed": 1.2, "food_cost": 1, "mana_cost": 5, "attack_type": "ranged", "proj": "orb", "splash": 30, "skill": "nova", "skill_cd": 12, "desc": "High Dmg AOE" },
	"phoenix":{ "name": "Phoenix", "icon": "🦅", "cost": 150, "size": Vector2i(1,1), "damage": 25, "range": 300, "atk_speed": 0.6, "food_cost": 10, "mana_cost": 0, "attack_type": "ranged", "proj": "fire", "splash": 40, "skill": "firestorm", "skill_cd": 20, "desc": "AOE Bomber" },
	"hydra":  { "name": "Hydra", "icon": "🐕", "cost": 120, "size": Vector2i(2,2), "damage": 40, "range": 120, "atk_speed": 0.8, "food_cost": 20, "mana_cost": 0, "attack_type": "melee", "skill": "devour_aura", "desc": "2x2 Beast" },
	"plant":  { "name": "Sunflower", "icon": "🌻", "cost": 20, "size": Vector2i(1,1), "damage": 0, "range": 0, "atk_speed": 1.0, "food_cost": -6, "mana_cost": 0, "attack_type": "none", "produce": "food", "produce_amt": 6, "desc": "Produce Food" },
	"crystal":{ "name": "Crystal", "icon": "💎", "cost": 30, "size": Vector2i(1,1), "damage": 0, "range": 0, "atk_speed": 1.0, "food_cost": 0, "mana_cost": -3, "attack_type": "none", "produce": "mana", "produce_amt": 3, "desc": "Produce Mana" },
	"torch":  { "name": "Torch", "icon": "🔥", "cost": 35, "size": Vector2i(1,1), "damage": 0, "range": 0, "atk_speed": 0, "food_cost": 0, "mana_cost": 0, "attack_type": "none", "buff_provider": "fire", "desc": "Buff: Burn" },
	"cauldron":{ "name": "Cauldron", "icon": "🧪", "cost": 35, "size": Vector2i(1,1), "damage": 0, "range": 0, "atk_speed": 0, "food_cost": 0, "mana_cost": 0, "attack_type": "none", "buff_provider": "poison", "desc": "Buff: Poison" },
	"prism":  { "name": "Prism", "icon": "🧊", "cost": 40, "size": Vector2i(1,1), "damage": 0, "range": 0, "atk_speed": 0, "food_cost": 0, "mana_cost": 0, "attack_type": "none", "buff_provider": "range", "desc": "Buff: Range" },
	"drum":   { "name": "Drum", "icon": "🥁", "cost": 40, "size": Vector2i(1,1), "damage": 0, "range": 0, "atk_speed": 0, "food_cost": 0, "mana_cost": 0, "attack_type": "none", "buff_provider": "speed", "desc": "Buff: Speed" },
	"lens":   { "name": "Lens", "icon": "🔍", "cost": 45, "size": Vector2i(1,1), "damage": 0, "range": 0, "atk_speed": 0, "food_cost": 0, "mana_cost": 0, "attack_type": "none", "buff_provider": "crit", "desc": "Buff: Crit" },
	"mirror": { "name": "Mirror", "icon": "🪞", "cost": 50, "size": Vector2i(1,1), "damage": 0, "range": 0, "atk_speed": 0, "food_cost": 0, "mana_cost": 0, "attack_type": "none", "buff_provider": "bounce", "desc": "Buff: Bounce" },
	"splitter":{ "name": "Splitter", "icon": "💠", "cost": 55, "size": Vector2i(1,1), "damage": 0, "range": 0, "atk_speed": 0, "food_cost": 0, "mana_cost": 0, "attack_type": "none", "buff_provider": "split", "desc": "Buff: Split" },
	"meat":   { "name": "Meat", "icon": "🥓", "cost": 10, "size": Vector2i(1,1), "damage": 0, "range": 0, "atk_speed": 0, "food_cost": 0, "mana_cost": 0, "is_food": true, "xp": 50, "attack_type": "none", "desc": "Feed for XP" }
}

const ENEMY_VARIANTS = {
	"slime": { "name": "Slime", "icon": "💧", "color": "#00cec9", "radius": 10, "hp_mod": 0.8, "spd_mod": 0.7, "attack_type": "melee", "range": 30, "dmg": 5, "drop": "mucus", "drop_rate": 0.5 },
	"poison":{ "name": "Poison", "icon": "🤢", "color": "#2ecc71", "radius": 12, "hp_mod": 1.2, "spd_mod": 0.8, "attack_type": "melee", "range": 30, "dmg": 8, "drop": "poison", "drop_rate": 0.4 },
	"wolf":  { "name": "Wolf", "icon": "🐺", "color": "#e74c3c", "radius": 14, "hp_mod": 1.0, "spd_mod": 1.5, "attack_type": "melee", "range": 30, "dmg": 12, "drop": "fang", "drop_rate": 0.3 },
	"treant":{ "name": "Treant", "icon": "🌳", "color": "#d35400", "radius": 18, "hp_mod": 2.5, "spd_mod": 0.5, "attack_type": "melee", "range": 30, "dmg": 20, "drop": "wood", "drop_rate": 0.6 },
	"yeti":  { "name": "Yeti", "icon": "❄️", "color": "#74b9ff", "radius": 20, "hp_mod": 3.0, "spd_mod": 0.6, "attack_type": "melee", "range": 40, "dmg": 25, "drop": "snow", "drop_rate": 0.5 },
	"golem": { "name": "Golem", "icon": "🗿", "color": "#95a5a6", "radius": 22, "hp_mod": 4.0, "spd_mod": 0.4, "attack_type": "melee", "range": 40, "dmg": 30, "drop": "stone", "drop_rate": 0.5 },
	"shooter":{ "name": "Shooter", "icon": "🏹", "color": "#16a085", "radius": 14, "hp_mod": 0.8, "spd_mod": 0.8, "attack_type": "ranged", "range": 200, "dmg": 8, "projectile_speed": 150, "drop": "wood", "drop_rate": 0.3 },
	"boss":   { "name": "Lord", "icon": "👹", "color": "#2c3e50", "radius": 32, "hp_mod": 15.0, "spd_mod": 0.4, "attack_type": "melee", "range": 50, "dmg": 50, "drop": "stone", "drop_rate": 1.0 }
}

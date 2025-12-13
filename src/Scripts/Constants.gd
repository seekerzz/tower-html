extends Node

const TILE_SIZE = 60
const BENCH_SIZE = 5

const MAP_WIDTH = 11
const MAP_HEIGHT = 11
const CORE_ZONE_RADIUS = 2

const BASE_CORE_HP = 500

const COLORS = {
	"bg": Color("#1a1a2e"),
	"grid": Color("#303045"),
	"enemy": Color("#e74c3c"),
	"projectile": Color("#f1c40f"),
	"enemyProjectile": Color("#e91e63"),
	"unlocked": Color("#303045"),
	"locked_inner": Color("#252535"),
	"locked_outer": Color("#151520"),
	"spawn_point": Color("#451515"),
	"core": Color("#4a3045")
}

const CORE_TYPES = {
	"cornucopia": { "name": "丰饶之角", "icon": "🌽", "desc": "基础食物产出 +100%。\n平稳发育，适合新手。", "bonus": { "foodRate": 50 } },
	"thunder":    { "name": "雷霆尖塔", "icon": "⚡", "desc": "核心每秒发射闪电攻击最近敌人。\n伤害: 200 (随波次成长)", "ability": "attack", "damage": 200 },
	"alchemy":    { "name": "炼金熔炉", "icon": "⚗️", "desc": "每秒产出 +20 法力。\n每波结束获得 10% 现有金币利息。", "bonus": { "manaRate": 20 } },
	"war":        { "name": "战争图腾", "icon": "⚔️", "desc": "食物产出减半。\n所有友军单位伤害 +50%。", "bonus": { "foodRate": -25, "globalDmg": 0.5 } }
}

const MATERIAL_TYPES = {
	"mucus": { "name": "粘液", "icon": "💧", "color": Color("#00cec9"), "desc": "减速陷阱" },
	"poison":{ "name": "毒药", "icon": "🧪", "color": Color("#2ecc71"), "desc": "毒雾屏障" },
	"fang":  { "name": "尖牙", "icon": "🦷", "color": Color("#e74c3c"), "desc": "尖刺陷阱" },
	"wood":  { "name": "木头", "icon": "🪵", "color": Color("#d35400"), "desc": "木栅栏" },
	"snow":  { "name": "雪团", "icon": "❄️", "color": Color("#74b9ff"), "desc": "冰墙" },
	"stone": { "name": "石头", "icon": "🪨", "color": Color("#95a5a6"), "desc": "石墙" }
}

const BARRICADE_TYPES = {
	"mucus": { "hp": 500, "type": "slow", "strength": 0.3, "color": Color("00cec9"), "width": 8, "name": "粘液网", "is_solid": false },
	"poison":{ "hp": 10, "type": "poison", "strength": 200, "color": Color("2ecc71"), "width": 20, "name": "毒雾", "immune": true, "is_solid": false },
	"fang":  { "hp": 800, "type": "reflect", "strength": 100, "color": Color("e74c3c"), "width": 6, "name": "荆棘", "is_solid": false },
	"wood":  { "hp": 2000, "type": "block", "strength": 0, "color": Color("d35400"), "width": 6, "name": "木栏", "is_solid": true },
	"snow":  { "hp": 2000, "type": "freeze", "strength": 1.5, "color": Color("74b9ff"), "width": 8, "name": "冰墙", "is_solid": true, "duration": 20.0, "immune": true },
	"stone": { "hp": 10000, "type": "block", "strength": 0, "color": Color("7f8c8d"), "width": 10, "name": "石墙", "is_solid": true, "immune": true }
}

const UNIT_TYPES = {
	"squirrel": { "name": "松鼠", "icon": "🐿️", "cost": 15, "size": Vector2i(1,1), "damage": 30, "range": 250, "atkSpeed": 0.15, "foodCost": 15, "manaCost": 0, "attackType": "ranged", "proj": "pinecone", "desc": "远程: 快速投掷松果", "damageType": "physical", "hp": 100, "crit_rate": 0.1, "crit_dmg": 1.5 },
	"octopus": { "name": "八爪鱼", "icon": "🐙", "cost": 60, "size": Vector2i(1,1), "damage": 120, "range": 180, "atkSpeed": 1.5, "foodCost": 30, "manaCost": 0, "attackType": "ranged", "proj": "ink", "projCount": 5, "spread": 0.5, "desc": "散射: 同时喷射多道墨汁", "damageType": "physical", "hp": 150, "crit_rate": 0.1, "crit_dmg": 1.5 },
	"bee": { "name": "蜜蜂", "icon": "🐝", "cost": 80, "size": Vector2i(1,1), "damage": 250, "range": 250, "atkSpeed": 0.8, "foodCost": 40, "manaCost": 0, "attackType": "ranged", "proj": "stinger", "pierce": 3, "desc": "穿透: 尖锐的蜂刺穿透敌人", "damageType": "physical", "hp": 180, "crit_rate": 0.2, "crit_dmg": 1.5 },
	"eel": { "name": "电鳗", "icon": "⚡", "cost": 70, "size": Vector2i(1,1), "damage": 350, "range": 200, "atkSpeed": 1.2, "foodCost": 50, "manaCost": 50, "attackType": "ranged", "proj": "lightning", "chain": 4, "desc": "连锁: 释放电流攻击多个敌人", "damageType": "lightning", "hp": 200, "crit_rate": 0.1, "crit_dmg": 1.5 },
	"lion": { "name": "狮子", "icon": "🦁", "cost": 90, "size": Vector2i(1,1), "damage": 400, "range": 200, "atkSpeed": 2.0, "foodCost": 80, "manaCost": 0, "attackType": "ranged", "proj": "roar", "desc": "声波: 狮吼造成范围伤害", "damageType": "poison", "hp": 200, "crit_rate": 0.1, "crit_dmg": 1.5 },
	"dragon": { "name": "龙", "icon": "🐉", "cost": 200, "size": Vector2i(1,1), "damage": 50, "range": 300, "atkSpeed": 3.0, "foodCost": 150, "manaCost": 200, "attackType": "ranged", "proj": "dragon_breath", "desc": "龙息: 持续燃烧并吸引敌人的区域", "damageType": "magic", "hp": 250, "crit_rate": 0.1, "crit_dmg": 1.5 },
	"dog": { "name": "恶霸犬", "icon": "🐕", "cost": 30, "size": Vector2i(1,1), "damage": 200, "range": 100, "atkSpeed": 0.8, "foodCost": 40, "manaCost": 0, "attackType": "melee", "splash": 60, "skill": "rage", "skillCd": 10, "desc": "近战: 凶猛撕咬 (范围伤害)", "damageType": "physical", "hp": 300, "crit_rate": 0.1, "crit_dmg": 1.5 },
	"bear":   { "name": "暴怒熊", "icon": "🐻", "cost": 65, "size": Vector2i(1,1), "damage": 350, "range": 80, "atkSpeed": 1.2, "foodCost": 50, "manaCost": 0, "attackType": "melee", "skill": "stun", "skillCd": 15, "desc": "近战:重击晕眩\n技能:震慑(300💧)", "damageType": "physical", "hp": 400, "crit_rate": 0.1, "crit_dmg": 1.5 },
	"butterfly": { "name": "蝴蝶", "icon": "🦋", "cost": 50, "size": Vector2i(1,1), "damage": 600, "range": 350, "atkSpeed": 1.2, "foodCost": 10, "manaCost": 50, "attackType": "ranged", "proj": "pollen", "splash": 30, "skill": "nova", "skillCd": 12, "desc": "魔法: 消耗法力释放强力花粉", "damageType": "magic", "hp": 150, "crit_rate": 0.1, "crit_dmg": 1.5 },
	"phoenix":{ "name": "凤凰", "icon": "🦅", "cost": 150, "size": Vector2i(1,1), "damage": 250, "range": 300, "atkSpeed": 0.6, "foodCost": 100, "manaCost": 0, "attackType": "ranged", "proj": "fire", "splash": 40, "skill": "firestorm", "skillCd": 20, "desc": "远程:AOE轰炸\n技能:火雨(300💧)", "damageType": "fire", "hp": 250, "crit_rate": 0.1, "crit_dmg": 1.5 },
	"plant":  { "name": "向日葵", "icon": "🌻", "cost": 20, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 1.0, "foodCost": -60, "manaCost": 0, "attackType": "none", "produce": "food", "produceAmt": 60, "desc": "产出:食物+60/s", "hp": 50, "crit_rate": 0.0, "crit_dmg": 1.5 },
	"torch":  { "name": "红莲火炬", "icon": "🔥", "cost": 35, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 0, "foodCost": 0, "manaCost": 0, "attackType": "none", "buffProvider": "fire", "desc": "邻接:赋予燃烧", "hp": 100, "crit_rate": 0.0, "crit_dmg": 1.5 },
	"cauldron":{ "name": "剧毒大锅", "icon": "🧪", "cost": 35, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 0, "foodCost": 0, "manaCost": 0, "attackType": "none", "buffProvider": "poison", "desc": "邻接:赋予中毒", "hp": 100, "crit_rate": 0.0, "crit_dmg": 1.5 },
	"drum":   { "name": "战鼓", "icon": "🥁", "cost": 40, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 0, "foodCost": 0, "manaCost": 0, "attackType": "none", "buffProvider": "speed", "desc": "邻接:攻速+20%", "hp": 100, "crit_rate": 0.0, "crit_dmg": 1.5 },
	"mirror": { "name": "反射魔镜", "icon": "🪞", "cost": 50, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 0, "foodCost": 0, "manaCost": 0, "attackType": "none", "buffProvider": "bounce", "desc": "邻接:子弹弹射+1", "hp": 100, "crit_rate": 0.0, "crit_dmg": 1.5 },
	"splitter":{ "name": "多重棱镜", "icon": "💠", "cost": 55, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 0, "foodCost": 0, "manaCost": 0, "attackType": "none", "buffProvider": "split", "desc": "邻接:子弹分裂+1", "hp": 100, "crit_rate": 0.0, "crit_dmg": 1.5 },
	"meat":   { "name": "五花肉", "icon": "🥓", "cost": 10, "size": Vector2i(1,1), "damage": 0, "range": 0, "atkSpeed": 0, "foodCost": 0, "manaCost": 0, "isFood": true, "xp": 50, "attackType": "none", "desc": "喂食获得大量Buff", "hp": 10, "crit_rate": 0.0, "crit_dmg": 1.5 }
}

const TRAITS = [
	{ "id": "vamp", "name": "吸血", "desc": "造成伤害回复生命", "icon": "🩸" },
	{ "id": "crit", "name": "暴击", "desc": "20%几率造成双倍伤害", "icon": "💥" },
	{ "id": "exec", "name": "处决", "desc": "对生命低于30%的敌人伤害翻倍", "icon": "💀" },
	{ "id": "giant", "name": "巨化", "desc": "体型变大，范围增加", "icon": "🏔️" },
	{ "id": "swift", "name": "神速", "desc": "攻速 +30%", "icon": "👟" }
]

const ENEMY_VARIANTS = {
	"slime": { "name": "史莱姆", "icon": "💧", "color": Color("#00cec9"), "radius": 10, "hpMod": 0.8, "spdMod": 0.7, "attackType": "melee", "range": 30, "dmg": 50, "atkSpeed": 1.0, "drop": "mucus", "dropRate": 0.5 },
	"poison":{ "name": "毒怪", "icon": "🤢", "color": Color("#2ecc71"), "radius": 12, "hpMod": 1.2, "spdMod": 0.8, "attackType": "melee", "range": 30, "dmg": 80, "atkSpeed": 1.0, "drop": "poison", "dropRate": 0.4 },
	"wolf":  { "name": "狼群", "icon": "🐺", "color": Color("#e74c3c"), "radius": 14, "hpMod": 1.0, "spdMod": 1.5, "attackType": "melee", "range": 30, "dmg": 120, "atkSpeed": 0.8, "drop": "fang", "dropRate": 0.3 },
	"treant":{ "name": "树人", "icon": "🌳", "color": Color("#d35400"), "radius": 18, "hpMod": 2.5, "spdMod": 0.5, "attackType": "melee", "range": 30, "dmg": 200, "atkSpeed": 2.0, "drop": "wood", "dropRate": 0.6 },
	"yeti":  { "name": "雪怪", "icon": "❄️", "color": Color("#74b9ff"), "radius": 20, "hpMod": 3.0, "spdMod": 0.6, "attackType": "melee", "range": 40, "dmg": 250, "atkSpeed": 2.0, "drop": "snow", "dropRate": 0.5 },
	"golem": { "name": "石头人", "icon": "🗿", "color": Color("#95a5a6"), "radius": 22, "hpMod": 4.0, "spdMod": 0.4, "attackType": "melee", "range": 40, "dmg": 300, "atkSpeed": 2.5, "drop": "stone", "dropRate": 0.5 },
	"shooter":{ "name": "投矛手", "icon": "🏹", "color": Color("#16a085"), "radius": 14, "hpMod": 0.8, "spdMod": 0.8, "attackType": "ranged", "range": 200, "dmg": 80, "atkSpeed": 2.0, "projectileSpeed": 150, "drop": "wood", "dropRate": 0.3 },
	"boss":   { "name": "虚空领主", "icon": "👹", "color": Color("#2c3e50"), "radius": 32, "hpMod": 15.0, "spdMod": 0.4, "attackType": "melee", "range": 50, "dmg": 500, "atkSpeed": 3.0, "drop": "stone", "dropRate": 1.0 }
}

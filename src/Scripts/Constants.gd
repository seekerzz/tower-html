extends Node

const TILE_SIZE = 60
const BENCH_SIZE = 8

const MAP_WIDTH = 9
const MAP_HEIGHT = 9
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

var CORE_TYPES = {}
var BARRICADE_TYPES = {
	"poison": { "name": "Poison Trap", "color": Color.GREEN, "is_solid": false },
	"fang": { "name": "Fang Trap", "color": Color.RED, "is_solid": false }
}
var UNIT_TYPES = {
	"phoenix": { "targetType": "ground", "damage": 50, "skill": "firestorm", "skillCd": 10.0, "skillCost": 30.0, "size": Vector2i(1, 1), "icon": "Phoenix" },
	"viper": { "targetType": "ground", "damage": 30, "skill": "trap_poison", "skillCd": 5.0, "skillCost": 20.0, "size": Vector2i(1, 1), "icon": "Viper" }
}
var TRAITS = []
var ENEMY_VARIANTS = {}

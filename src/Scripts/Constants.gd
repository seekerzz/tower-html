extends Node

const TILE_SIZE = 60
const BENCH_SIZE = 8

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

var CORE_TYPES = {}
var BARRICADE_TYPES = {}
var UNIT_TYPES = {}
var TRAITS = []
var ENEMY_VARIANTS = {}

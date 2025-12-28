extends Node

const TILE_SIZE = 60
const O_MAX = TILE_SIZE / 2.0
const G_MAX = TILE_SIZE
const R_MARGIN = TILE_SIZE / 6.0

const BENCH_SIZE = 8

const MAP_WIDTH = 9
const MAP_HEIGHT = 9
const CORE_ZONE_RADIUS = 2

const BASE_CORE_HP = 500

const POISON_TICK_INTERVAL = 0.5
const POISON_DAMAGE_RATIO = 0.1
const POISON_MAX_STACKS = 9999
const POISON_TRAP_MULTIPLIER = 1.1
const POISON_TRAP_INTERVAL = 1.0
const POISON_VISUAL_SATURATION_STACKS = 50

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
	"core": Color("#4a3045"),
	"border_line": Color("#4a4a58")
}

var CORE_TYPES = {}
var BARRICADE_TYPES = {}
var UNIT_TYPES = {}
var TRAITS = []
var ENEMY_VARIANTS = {}

const ENVIRONMENT_CONFIG = {
	"tree_tile_set": "res://assets/images/UI/tile_trees.png",
	"tree_columns": 3,
	"tree_rows": 3
}

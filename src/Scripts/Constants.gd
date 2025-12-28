extends Node

const TILE_SIZE = 60
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
	"core": Color("#4a3045")
}

var CORE_TYPES = {}
var BARRICADE_TYPES = {}
var UNIT_TYPES = {}
var TRAITS = []
var ENEMY_VARIANTS = {}

const ENVIRONMENT_CONFIG = {
	"tree_atlas_path": "res://assets/images/UI/tile_trees.png",
	"atlas_columns": 3,
	"atlas_rows": 3,
	"random_offset_px": 15.0,
	"scale_range": Vector2(0.9, 1.0)
}

static func get_theme_config(_theme_id: String = "default") -> Dictionary:
	return ENVIRONMENT_CONFIG

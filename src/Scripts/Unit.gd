extends Node2D

var type_key: String
var level: int = 1
var stats_multiplier: float = 1.0
var cooldown: float = 0.0
var skill_cooldown: float = 0.0
var active_buffs: Array = []
var traits: Array = []
var unit_data: Dictionary

# Stats
var damage: float
var range_val: float
var atk_speed: float

signal unit_clicked(unit)

func setup(key: String):
	type_key = key
	unit_data = Constants.UNIT_TYPES[key].duplicate()
	damage = unit_data.damage
	range_val = unit_data.range
	atk_speed = unit_data.atk_speed if "atk_speed" in unit_data else unit_data.atkSpeed

	update_visuals()

func update_visuals():
	$Label.text = unit_data.icon
	# Size update
	var size = unit_data.size
	$ColorRect.size = Vector2(size.x * 60 - 4, size.y * 60 - 4)
	$ColorRect.position = -($ColorRect.size / 2)
	$Label.position = $ColorRect.position
	$Label.size = $ColorRect.size

	if level > 1:
		$StarLabel.text = "⭐%d" % level
		$StarLabel.show()
	else:
		$StarLabel.hide()

func _process(delta):
	if !GameManager.is_wave_active: return

	if cooldown > 0:
		cooldown -= delta

	if skill_cooldown > 0:
		skill_cooldown -= delta

	# Attack Logic (simplified for now, needs Enemy reference)
	# This will be handled by CombatManager or Unit itself if it has access to enemies

func merge_with(other_unit):
	level += 1
	damage *= 1.5
	stats_multiplier += 0.5
	update_visuals()
	# Play animation

func devour(food_unit):
	level += 1
	damage += 5
	stats_multiplier += 0.2
	update_visuals()

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		unit_clicked.emit(self)

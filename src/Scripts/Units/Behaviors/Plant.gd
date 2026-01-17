extends "res://src/Scripts/Units/DefaultBehavior.gd"

var production_timer: float = 0.0
var max_production_timer: float = 1.0

func on_setup():
	production_timer = max_production_timer

func on_tick(delta):
	production_timer -= delta
	if production_timer <= 0:
		var p_type = unit.unit_data.get("produce", "mana")
		var p_amt = unit.unit_data.get("produceAmt", 1)

		GameManager.add_resource(p_type, p_amt)
		var icon = "💎"
		GameManager.spawn_floating_text(unit.global_position, "+%d%s" % [p_amt, icon], Color.CYAN)

		production_timer = max_production_timer

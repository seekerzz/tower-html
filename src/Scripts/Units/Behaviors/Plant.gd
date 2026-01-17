extends DefaultBehavior
var production_timer: float = 1.0

func on_tick(delta: float):
	production_timer -= delta
	if production_timer <= 0:
		var p_type = unit.unit_data.produce
		var p_amt = unit.unit_data.get("produceAmt", 1)

		GameManager.add_resource(p_type, p_amt)
		var icon = "💎"
		GameManager.spawn_floating_text(unit.global_position, "+%d%s" % [p_amt, icon], Color.CYAN)
		production_timer = 1.0

extends DefaultBehavior

var production_timer: float = 0.0

func on_setup():
	production_timer = 1.0

func on_tick(delta: float):
	production_timer -= delta
	if production_timer <= 0:
		var p_type = unit.unit_data.get("produce", "mana")
		var p_amt = unit.unit_data.get("produceAmt", 1)

		# Check level scaling for amount if needed (not in original code but good practice,
		# Unit.gd just used unit_data.get("produceAmt", 1) which might be base data)
		# Original code: var p_amt = unit_data.get("produceAmt", 1)

		GameManager.add_resource(p_type, p_amt)

		var icon = "💎"
		var color = Color.CYAN
		GameManager.spawn_floating_text(unit.global_position, "+%d%s" % [p_amt, icon], color)

		production_timer = 1.0

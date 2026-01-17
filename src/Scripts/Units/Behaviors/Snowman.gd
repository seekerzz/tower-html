extends "res://src/Scripts/Units/DefaultBehavior.gd"

var production_timer: float = 0.0
var max_production_timer: float = 1.0

func on_setup():
	on_stats_updated()
	production_timer = max_production_timer

func on_stats_updated():
	max_production_timer = unit.unit_data.get("production_interval", 5.0)
	if unit.unit_data.has("levels") and unit.unit_data["levels"].has(str(unit.level)):
		var stats = unit.unit_data["levels"][str(unit.level)]
		if stats.has("mechanics") and stats["mechanics"].has("production_interval"):
			max_production_timer = stats["mechanics"]["production_interval"]

func on_tick(delta):
	production_timer -= delta
	if production_timer <= 0:
		var item_id = unit.unit_data.get("produce_item_id", "")
		if item_id != "":
			var item_data = { "item_id": item_id, "count": 1 }
			var added = false
			if GameManager.inventory_manager:
				if GameManager.inventory_manager.add_item(item_data):
					added = true
			else:
				added = true # Test fallback

			if added:
				var trap_name = "Trap"
				if Constants.BARRICADE_TYPES.has(item_id):
					trap_name = Constants.BARRICADE_TYPES[item_id].get("icon", "Trap")
				GameManager.spawn_floating_text(unit.global_position, "%s Produced!" % trap_name, Color.GREEN)
				production_timer = max_production_timer
			else:
				production_timer = 0.0 # Retry

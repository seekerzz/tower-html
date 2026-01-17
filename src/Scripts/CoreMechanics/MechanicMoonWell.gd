extends CoreMechanic

var moonwell_pool: float = 0.0

func on_damage_dealt_by_unit(unit, amount: float):
	moonwell_pool += amount * 0.1

func on_wave_started():
	var item_data = { "item_id": "moon_water", "count": 1 }
	if GameManager.inventory_manager:
		if !GameManager.inventory_manager.add_item(item_data):
			GameManager.spawn_floating_text(Vector2(0, 0), "Inventory Full!", Color.RED)

func consume_moonwell_pool() -> float:
	var amount = moonwell_pool
	moonwell_pool = 0.0
	return amount

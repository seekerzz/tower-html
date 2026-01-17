extends CoreMechanic

func on_wave_started():
	var item_data = { "item_id": "holy_sword", "count": 1 }
	if GameManager.inventory_manager:
		if !GameManager.inventory_manager.add_item(item_data):
			GameManager.spawn_floating_text(Vector2(0, 0), "Inventory Full!", Color.RED)

extends Node

signal shop_updated

var shop_items = []
var bench = [null, null, null, null, null]
const BENCH_SIZE = 5

func _ready():
	generate_shop_items(true)

func generate_shop_items(force_all: bool = false):
	var keys = UnitData.UNIT_TYPES.keys()
	var new_items = []
	for i in range(4):
		if !force_all and i < shop_items.size() and shop_items[i].locked:
			new_items.append(shop_items[i])
		else:
			var key = keys[randi() % keys.size()]
			new_items.append({ "key": key, "locked": false })

	shop_items = new_items
	emit_signal("shop_updated")

func buy_unit(index: int) -> bool:
	if index < 0 or index >= shop_items.size():
		return false

	var item = shop_items[index]
	var unit_data = UnitData.UNIT_TYPES[item.key]

	if GameManager.gold >= unit_data.cost:
		if add_to_bench(item.key):
			GameManager.spend_gold(unit_data.cost)
			# We don't remove the item from shop in this game logic based on ref,
			# usually shops replace item with empty or sold out.
			# ref.html logic: "if (addToBench(newUnit)) ... game.gold -= proto.cost"
			# It does NOT remove the item from the shop card immediately, so you can buy multiples if you have money?
			# Wait, "generateShopItems" is called only on refresh or wave start.
			# So yes, you can buy multiples of the same card in this implementation?
			# Actually in ref.html, `buyUnitFromShop` doesn't remove the card.
			return true
	return false

func add_to_bench(key: String) -> bool:
	for i in range(BENCH_SIZE):
		if bench[i] == null:
			bench[i] = { "key": key, "level": 1 }
			emit_signal("shop_updated")
			return true
	return false

func reroll_shop():
	if GameManager.spend_gold(10):
		generate_shop_items(false)

func toggle_lock(index: int):
	if index >= 0 and index < shop_items.size():
		shop_items[index].locked = !shop_items[index].locked
		emit_signal("shop_updated")

func sell_bench_unit(index: int):
	if index >= 0 and index < BENCH_SIZE and bench[index] != null:
		var key = bench[index].key
		var cost = UnitData.UNIT_TYPES[key].cost
		GameManager.add_gold(int(cost * 0.5))
		bench[index] = null
		emit_signal("shop_updated")

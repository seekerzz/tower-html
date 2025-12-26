extends Node

class_name InventoryManager

# 1. 修改信号定义，增加 items 参数
signal inventory_updated(items)

# Schema: { "item_id": String, "icon": String, "skill_source": String (optional), "count": int }
var items: Array = []

func _init():
	pass

# 2. 添加缺失的接口方法，供 InventoryPanel 初始化调用
func get_inventory() -> Array:
	return items

func add_item(item_data: Dictionary) -> bool:
	# Try to stack first
	for item in items:
		if item.get("item_id") == item_data.get("item_id"):
			item["count"] += item_data.get("count", 1)
			inventory_updated.emit(items)
			return true

	# Append new item
	var new_item = item_data.duplicate()
	if not new_item.has("count"):
		new_item["count"] = 1
	items.append(new_item)

	inventory_updated.emit(items)
	return true

func remove_item(index: int):
	if index >= 0 and index < items.size():
		items[index]["count"] -= 1
		if items[index]["count"] <= 0:
			items.remove_at(index)
		inventory_updated.emit(items)

func get_item(index: int):
	if index >= 0 and index < items.size():
		return items[index]
	return null

func get_item_count(index: int) -> int:
	var item = get_item(index)
	if item:
		return item.get("count", 0)
	return 0

func is_full() -> bool:
	for item in items:
		if item == null:
			return false
	return true

extends Node

func _ready():
	print("Starting TestDataLoading...")

	call_deferred("_run_tests")

func _run_tests():
	var DataManagerScript = load("res://src/Scripts/Managers/DataManager.gd")
	var data_manager = DataManagerScript.new()
	data_manager.load_data()

	if not Constants:
		print("ERROR: Constants autoload not found.")
		get_tree().quit()
		return

	if Constants.UNIT_TYPES.size() == 0:
		print("FAILURE: UNIT_TYPES is empty")
	else:
		print("SUCCESS: UNIT_TYPES is not empty")

	var squirrel = Constants.UNIT_TYPES.get("squirrel")
	if squirrel.damage == 30:
		print("SUCCESS: Squirrel damage is 30")
	else:
		print("FAILURE: Squirrel damage is ", squirrel.damage)

	if typeof(squirrel.size) == TYPE_VECTOR2I:
		print("SUCCESS: Squirrel size is Vector2i")
	else:
		print("FAILURE: Squirrel size is ", typeof(squirrel.size))

	if squirrel.size == Vector2i(1, 1):
		print("SUCCESS: Squirrel size is (1, 1)")
	else:
		print("FAILURE: Squirrel size is ", squirrel.size)

	var slime = Constants.ENEMY_VARIANTS.get("slime")
	if typeof(slime.color) == TYPE_COLOR:
		print("SUCCESS: Slime color is Color")
	else:
		print("FAILURE: Slime color is ", typeof(slime.color))

	if slime.color.to_html(false) == "00cec9":
		print("SUCCESS: Slime color hex matches")
	else:
		print("FAILURE: Slime color hex is ", slime.color.to_html(false))

	print("PASS: Data loaded and parsed correctly from JSON.")

	data_manager.free()
	get_tree().quit()

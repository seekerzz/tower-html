extends Node

var unit_script = preload("res://src/Scripts/Unit.gd")
var passive_bar_script = preload("res://src/Scripts/UI/PassiveSkillBar.gd")

func _ready():
	print("Starting TestPassiveCD...")
	Test_Viper_Max_Timer()
	Test_UI_Sync()
	print("All tests passed!")
	get_tree().quit()

func Test_Viper_Max_Timer():
	print("Running Test_Viper_Max_Timer...")
	var unit = Node2D.new()
	unit.set_script(unit_script)
	# Mock unit_data and hierarchy
	unit.name = "TestViper"

	# We need to ensure Constants.UNIT_TYPES["viper"] exists or we mock it.
	# Unit.gd uses Constants.UNIT_TYPES. Let's rely on it being present or mock it if possible.
	# Since Constants is global, we assume it's loaded.

	# However, Unit.gd `setup` duplicates `Constants.UNIT_TYPES[key]`.
	# If this is run in a standalone scene, Constants autoload might not be there depending on how we run it.
	# But we are using `run_in_bash_session` to run godot. If we run a scene, autoloads are loaded if defined in project.godot.
	# Assuming Constants is an Autoload.

	# Calling setup("viper")
	unit.setup("viper")

	if unit.max_production_timer != 5.0:
		push_error("Test_Viper_Max_Timer Failed: max_production_timer is %s, expected 5.0" % unit.max_production_timer)
		get_tree().quit(1)
		return

	print("Test_Viper_Max_Timer Passed.")
	unit.free()

func Test_UI_Sync():
	print("Running Test_UI_Sync...")

	# Mock Unit
	var mock_unit = Node2D.new()
	mock_unit.set_script(unit_script)
	mock_unit.max_production_timer = 5.0
	mock_unit.production_timer = 2.5
	mock_unit.type_key = "viper" # To match filter in PassiveSkillBar

	# Mock PassiveSkillBar
	var bar = Control.new()
	bar.set_script(passive_bar_script)

	# Need to mock the hierarchy expected by PassiveSkillBar
	# @onready var container = $PanelContainer/GridContainer
	var panel = PanelContainer.new()
	panel.name = "PanelContainer"
	var grid = GridContainer.new()
	grid.name = "GridContainer"
	panel.add_child(grid)
	bar.add_child(panel)

	# Force ready
	bar._ready()

	# Inject unit into monitored_units manually or mock GridManager
	# Ideally we mock GridManager to return our unit.
	# Or since `monitored_units` is not exposed, we can rely on `refresh_units`
	# but `refresh_units` calls `GameManager.grid_manager.tiles`.

	# We can modify monitored_units directly if it was public, but it is.
	# Wait, `monitored_units` is a var in the script.
	bar.monitored_units = [mock_unit]
	bar._create_card(mock_unit)

	# Run _process
	bar._process(0.1)

	# Verify UI
	# Card is child of container
	var card = grid.get_child(0)
	var layout = card.get_child(0)
	var cd_bar = layout.get_node("CD_Overlay")

	if cd_bar.max_value != 5.0:
		push_error("Test_UI_Sync Failed: max_value is %s, expected 5.0" % cd_bar.max_value)
		get_tree().quit(1)
		return

	if abs(cd_bar.value - 2.5) > 0.001:
		push_error("Test_UI_Sync Failed: value is %s, expected 2.5" % cd_bar.value)
		get_tree().quit(1)
		return

	print("Test_UI_Sync Passed.")
	mock_unit.free()
	bar.free()

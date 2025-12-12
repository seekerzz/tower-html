extends SceneTree

func _init():
	print("Starting Enemy Attack Syntax Check")

	# Attempt to load the script. This triggers compilation.
	# If there are syntax errors, it should fail here.
	# Note: Runtime errors due to missing Autoloads (GameManager, Constants)
	# might happen if _init or _ready are called, but just loading the resource
	# primarily checks syntax and class structure.

	var script_path = "res://src/Scripts/Enemy.gd"
	if ResourceLoader.exists(script_path):
		var script = load(script_path)
		if script:
			print("Successfully loaded Enemy.gd - Syntax is valid.")
		else:
			print("Failed to load Enemy.gd")
	else:
		print("Enemy.gd does not exist")

	quit()

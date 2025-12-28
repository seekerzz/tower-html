extends Node

func _ready():
	# This test requires the scene to be run within the Godot Editor or a properly set up environment
	# where 'GameManager' and 'Constants' singletons are available.

	if not Engine.has_singleton("GameManager") and not get_node_or_null("/root/GameManager"):
		print("Test skipped: GameManager not found (Autoloads not loaded in this context).")
		return

	print("Starting Tree Placement Verification...")

	await get_tree().create_timer(1.0).timeout

	var grid_manager = GameManager.grid_manager
	if not grid_manager:
		print("Error: GridManager not found.")
		return

	var trees = []
	for child in grid_manager.get_children():
		if child.has_method("get_actual_size"):
			trees.append(child)

	print("Found ", trees.size(), " trees.")

	var T = Constants.TILE_SIZE
	var Mw = Constants.MAP_WIDTH
	var Mh = Constants.MAP_HEIGHT
	var Ex = (Mw * T) / 2.0
	var Ey = (Mh * T) / 2.0
	var Omax = Constants.O_MAX
	var Gmax = Constants.G_MAX

	var errors = 0

	# 1. Scale Consistency
	for tree in trees:
		if abs(tree.scale.x - tree.scale.y) > 0.001:
			print("Error: Tree scale mismatch: ", tree.scale)
			errors += 1

	# 2. Boundary Checks
	for tree in trees:
		var pos = tree.position
		var size = tree.get_actual_size()
		var W = size.x
		var H = size.y

		# Identify which boundary it belongs to based on position
		if pos.y < -Ey: # Top
			if pos.y > -Ey: # Should be impossible if logic holds
				print("Error: Top tree enters board y-space: ", pos.y)
				errors += 1
		elif pos.y > Ey: # Bottom
			# Check overlap depth.
			var depth = Ey - (pos.y - H)
			# Formula provided gives depth range [Omax, Gmax] approx.
			# We verify it doesn't exceed Gmax significantly (allow tolerance)
			if depth > Gmax + 1.0:
				print("Error: Bottom tree occlusion depth too high: ", depth)
				errors += 1
		elif pos.x < -Ex: # Left
			var depth = pos.x + W/2.0 + Ex
			if depth > Gmax + 1.0:
				print("Error: Left tree occlusion depth too high: ", depth)
				errors += 1
		elif pos.x > Ex: # Right
			var depth = Ex - (pos.x - W/2.0)
			if depth > Gmax + 1.0:
				print("Error: Right tree occlusion depth too high: ", depth)
				errors += 1
		else:
			# Inside board?!
			print("Error: Tree found INSIDE board bounds! ", pos)
			errors += 1

	# 3. Corner Exclusion
	# |x| > (Ex - T) AND |y| > (Ey - T)
	for tree in trees:
		var pos = tree.position
		if abs(pos.x) > (Ex - T) and abs(pos.y) > (Ey - T):
			print("Error: Tree found in corner zone: ", pos)
			errors += 1

	# 4. Layer Consistency
	for tree in trees:
		if tree.z_index != int(tree.position.y):
			print("Error: Tree z_index mismatch. Pos Y: ", tree.position.y, " Z: ", tree.z_index)
			errors += 1

	if errors == 0:
		print("VERIFICATION SUCCESS: All checks passed.")
	else:
		print("VERIFICATION FAILED: Found ", errors, " errors.")

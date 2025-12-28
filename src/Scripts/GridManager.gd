extends Node2D

var TILE_SCENE = null
const UNIT_SCENE = preload("res://src/Scenes/Game/Unit.tscn")
const TREE_SCENE = preload("res://src/Scenes/Game/Tree.tscn")
var BARRICADE_SCENE = null
const GHOST_TILE_SCRIPT = preload("res://src/Scripts/UI/GhostTile.gd")
const TILE_SIZE = 60

var tiles: Dictionary = {} # Key: "x,y", Value: Tile Instance
var obstacles: Dictionary = {} # Key: Vector2i, Value: Obstacle
var obstacle_map: Dictionary = {} # Key: Node, Value: Vector2i (Grid Pos)
var ghost_tiles: Array = []
var expansion_mode: bool = false
var expansion_cost: int = 50 # Base cost
var spawn_tiles: Array = [] # List of tiles (Vector2i) used as spawn points
var active_territory_tiles: Array = [] # List of Tile instances that are unlocked or core

@export var border_margin: float = 8.0

# Interaction / Skill Targeting
var placement_preview_cursor: Node2D = null
var last_preview_frame: int = 0

# Interaction System (Neighbor Buff Selection)
const STATE_IDLE = 0
const STATE_SELECTING_INTERACTION_TARGET = 1
const STATE_SKILL_TARGETING = 2

var interaction_state: int = STATE_IDLE
var interaction_source_unit = null
var skill_source_unit: Node2D = null
var skill_preview_node: Node2D = null

var valid_interaction_targets: Array = [] # Array[Vector2i]
var interaction_highlights: Array = [] # Array[Node2D] (Visuals)

var selection_overlay: Node2D = null
var astar_grid: AStarGrid2D

signal grid_updated

func _ready():
	GameManager.grid_manager = self

	selection_overlay = Node2D.new()
	selection_overlay.name = "SelectionOverlay"
	selection_overlay.z_index = 100
	selection_overlay.draw.connect(_on_selection_overlay_draw)
	add_child(selection_overlay)

	TILE_SCENE = load("res://src/Scenes/Game/Tile.tscn")
	if ResourceLoader.exists("res://src/Scenes/Game/Barricade.tscn"):
		BARRICADE_SCENE = load("res://src/Scenes/Game/Barricade.tscn")
	_init_astar()
	create_initial_grid()
	_create_map_boundaries()
	_setup_tree_border()
	_setup_border_visual()
	# _generate_random_obstacles()

func grid_to_local(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)

func local_to_grid(local_pos: Vector2) -> Vector2i:
	return Vector2i(round(local_pos.x / TILE_SIZE), round(local_pos.y / TILE_SIZE))

func _setup_border_visual():
	var border_line = Line2D.new()
	border_line.name = "BorderLine"
	border_line.z_index = -10
	border_line.width = 3.0
	border_line.antialiased = true
	border_line.default_color = Constants.COLORS.border_line
	add_child(border_line)

	# Calculate bounds based on grid structure
	# Grid is centered at (0,0) and extends from -half_w to +half_w (indices)
	var half_grid_w = floor(Constants.MAP_WIDTH / 2.0)
	var half_grid_h = floor(Constants.MAP_HEIGHT / 2.0)

	# Top-Left corner of the top-left tile
	var min_grid_pos = Vector2i(-half_grid_w, -half_grid_h)
	# Bottom-Right corner of the bottom-right tile
	var max_grid_pos = Vector2i(half_grid_w, half_grid_h)

	# grid_to_local gives center of tile.
	# We want outer edges.
	var top_left = grid_to_local(min_grid_pos) - Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0) - Vector2(border_margin, border_margin)
	var bottom_right = grid_to_local(max_grid_pos) + Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0) + Vector2(border_margin, border_margin)

	var rect = Rect2(top_left, bottom_right - top_left)
	var radius = 15.0 # Arbitrary visual radius for rounded corners

	var points = _generate_rounded_rect_path(rect, radius)
	points = _subdivide_path(points, 10.0)
	points = _apply_jitter_to_path(points, 1.5)

	border_line.points = points

	# Width curve
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(0.25, 0.9))
	curve.add_point(Vector2(0.5, 1.2)) # Slight swell
	curve.add_point(Vector2(0.75, 1.1))
	curve.add_point(Vector2(1, 1))
	border_line.width_curve = curve

func _generate_rounded_rect_path(rect: Rect2, r: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	var steps = 8 # Number of segments for corner

	# Top Left Corner
	var c_tl = rect.position + Vector2(r, r)
	for i in range(steps + 1):
		var angle = PI + (PI / 2.0 * i / steps)
		points.append(c_tl + Vector2(cos(angle), sin(angle)) * r)

	# Top Right Corner
	var c_tr = rect.position + Vector2(rect.size.x - r, r)
	for i in range(steps + 1):
		var angle = 1.5 * PI + (PI / 2.0 * i / steps)
		points.append(c_tr + Vector2(cos(angle), sin(angle)) * r)

	# Bottom Right Corner
	var c_br = rect.position + Vector2(rect.size.x - r, rect.size.y - r)
	for i in range(steps + 1):
		var angle = 0.0 + (PI / 2.0 * i / steps)
		points.append(c_br + Vector2(cos(angle), sin(angle)) * r)

	# Bottom Left Corner
	var c_bl = rect.position + Vector2(r, rect.size.y - r)
	for i in range(steps + 1):
		var angle = 0.5 * PI + (PI / 2.0 * i / steps)
		points.append(c_bl + Vector2(cos(angle), sin(angle)) * r)

	# Close the loop
	points.append(points[0])

	return points

func _subdivide_path(points: PackedVector2Array, min_segment_len: float) -> PackedVector2Array:
	var new_points = PackedVector2Array()
	for i in range(points.size() - 1):
		var p1 = points[i]
		var p2 = points[i+1]
		var dist = p1.distance_to(p2)
		var segments = ceil(dist / min_segment_len)

		for j in range(segments):
			var t = j / segments
			new_points.append(p1.lerp(p2, t))

	new_points.append(points[-1])
	return new_points

func _apply_jitter_to_path(points: PackedVector2Array, magnitude: float) -> PackedVector2Array:
	var new_points = PackedVector2Array()

	# Skip the last point in the loop since it should match the first
	for i in range(points.size() - 1):
		var p = points[i]

		# Calculate Normal
		var prev = points[(i - 1 + points.size()) % points.size()]
		var next = points[(i + 1) % points.size()]
		var tangent = (next - prev).normalized()
		var normal = Vector2(-tangent.y, tangent.x)

		var offset = normal * randf_range(-magnitude, magnitude)
		new_points.append(p + offset)

	# Close loop by duplicating the jittered first point
	new_points.append(new_points[0])

	return new_points

func _setup_tree_border():
	print("Generating tree border (Refactored)...")

	# Constants
	var T = Constants.TILE_SIZE
	var Mw = Constants.MAP_WIDTH
	var Mh = Constants.MAP_HEIGHT
	var Ex = (Mw * T) / 2.0
	var Ey = (Mh * T) / 2.0
	var Omax = Constants.O_MAX
	var Gmax = Constants.G_MAX
	var Rmargin = Constants.R_MARGIN

	# Number of trees to attempt
	var attempts_per_side = 20 # Increased density check

	var sides = ["Top", "Bottom", "Left", "Right"]

	for i in range(80): # Total attempts
		var side = sides.pick_random()

		# 1. Instantiate and Setup Tree
		var tree = TREE_SCENE.instantiate()
		var w_tiles = randi_range(2, 4)
		tree.setup(w_tiles)

		# 2. Get Actual Dimensions
		var size = tree.get_actual_size()
		var W = size.x
		var H = size.y

		# 3. Calculate Valid Interval
		var valid_range_min = 0.0
		var valid_range_max = 0.0
		var axis = "x" # "x" means varies along X (Top/Bottom), "y" means varies along Y (Left/Right)
		var fixed_coord = 0.0 # Not exactly fixed, but constrained range

		var pos_x = 0.0
		var pos_y = 0.0

		match side:
			"Top":
				# Visual Top (Godot -Y)
				# User Formula (Translated): Y_godot in [-(Ey + Gmax), -(Ey + Rmargin)]
				var y_min = -(Ey + Gmax)
				var y_max = -(Ey + Rmargin)
				pos_y = randf_range(y_min, y_max)

				# X Range: Roughly -Ex to Ex, but can go slightly wider?
				# Prompt doesn't specify X interval for Top/Bottom, only "randomly execute placement" in "intervals".
				# Usually along the edge.
				# Let's assume full width +/- extra?
				# Let's use [-Ex - T, Ex + T] to cover corners too (though corners are excluded later)
				pos_x = randf_range(-Ex - T, Ex + T)

			"Bottom":
				# Visual Bottom (Godot +Y)
				# User Formula (Translated): Y_godot in [Ey + H - Gmax, Ey + H - Omax]
				# Wait, my previous derivation:
				# User Y in [-(Ey + H - Omax), -(Ey + H - Gmax)]
				# Godot Y = -User Y => [Ey + H - Gmax, Ey + H - Omax]
				# Wait, Omax (30) < Gmax (60).
				# Ey + H - 60 (Smaller) vs Ey + H - 30 (Larger).
				# So range is valid.
				var y_min = Ey + H - Gmax
				var y_max = Ey + H - Omax
				pos_y = randf_range(y_min, y_max)

				pos_x = randf_range(-Ex - T, Ex + T)

			"Left":
				# Left (Godot -X)
				# User Formula: X in [-(Ex + W/2 - Omax), -(Ex + W/2 - Gmax)]
				# Ex + W/2 - Omax is Larger Magnitude.
				# Ex + W/2 - Gmax is Smaller Magnitude.
				# Negative of Larger is Smaller (more negative).
				# Interval: [-(Ex + W/2 - Omax), -(Ex + W/2 - Gmax)]
				var x_min = -(Ex + W / 2.0 - Omax) # More negative
				var x_max = -(Ex + W / 2.0 - Gmax) # Less negative
				pos_x = randf_range(x_min, x_max)

				# Y Range: [-Ey - T, Ey + T]
				pos_y = randf_range(-Ey - T, Ey + T)

			"Right":
				# Right (Godot +X)
				# User Formula: X in [Ex + W/2 - Omax, Ex + W/2 - Gmax]
				# Wait. Ex + W/2 - Omax (Larger). Ex + W/2 - Gmax (Smaller).
				# Interval should be [Smaller, Larger].
				# [Ex + W/2 - Gmax, Ex + W/2 - Omax]
				var x_min = Ex + W / 2.0 - Gmax
				var x_max = Ex + W / 2.0 - Omax
				pos_x = randf_range(x_min, x_max)

				# Y Range
				pos_y = randf_range(-Ey - T, Ey + T)

		# 4. Corner Exclusion
		# |x| > (Ex - T) AND |y| > (Ey - T)
		if abs(pos_x) > (Ex - T) and abs(pos_y) > (Ey - T):
			tree.queue_free()
			continue

		# 5. Place
		add_child(tree)
		tree.position = Vector2(pos_x, pos_y)
		tree.z_index = int(pos_y) # Z-index based on Y

func _create_map_boundaries():
	var border_body = StaticBody2D.new()
	border_body.name = "MapBorder"
	border_body.collision_layer = 1 # Wall layer
	border_body.collision_mask = 0
	add_child(border_body)

	var map_w_pixels = Constants.MAP_WIDTH * TILE_SIZE
	var map_h_pixels = Constants.MAP_HEIGHT * TILE_SIZE
	var wall_thickness = 100.0

	# Top Wall
	var top_shape = CollisionShape2D.new()
	var top_rect = RectangleShape2D.new()
	top_rect.size = Vector2(map_w_pixels + wall_thickness * 2, wall_thickness)
	top_shape.shape = top_rect
	top_shape.position = Vector2(0, -map_h_pixels/2.0 - wall_thickness/2.0)
	border_body.add_child(top_shape)

	# Bottom Wall
	var bot_shape = CollisionShape2D.new()
	var bot_rect = RectangleShape2D.new()
	bot_rect.size = Vector2(map_w_pixels + wall_thickness * 2, wall_thickness)
	bot_shape.shape = bot_rect
	bot_shape.position = Vector2(0, map_h_pixels/2.0 + wall_thickness/2.0)
	border_body.add_child(bot_shape)

	# Left Wall
	var left_shape = CollisionShape2D.new()
	var left_rect = RectangleShape2D.new()
	left_rect.size = Vector2(wall_thickness, map_h_pixels + wall_thickness * 2)
	left_shape.shape = left_rect
	left_shape.position = Vector2(-map_w_pixels/2.0 - wall_thickness/2.0, 0)
	border_body.add_child(left_shape)

	# Right Wall
	var right_shape = CollisionShape2D.new()
	var right_rect = RectangleShape2D.new()
	right_rect.size = Vector2(wall_thickness, map_h_pixels + wall_thickness * 2)
	right_shape.shape = right_rect
	right_shape.position = Vector2(map_w_pixels/2.0 + wall_thickness/2.0, 0)
	border_body.add_child(right_shape)

func _process(_delta):
	if placement_preview_cursor and placement_preview_cursor.visible:
		var dist = get_global_mouse_position().distance_to(placement_preview_cursor.global_position)
		var frame_diff = Engine.get_process_frames() - last_preview_frame

		if dist > 50.0 and frame_diff > 10:
			print("[Debug] Hiding preview cursor. Dist: ", dist, " Frames: ", frame_diff)
			placement_preview_cursor.visible = false

	if interaction_state == STATE_SELECTING_INTERACTION_TARGET:
		selection_overlay.queue_redraw()

	if interaction_state == STATE_SKILL_TARGETING and skill_preview_node and is_instance_valid(skill_preview_node):
		var mouse_pos = get_local_mouse_position()
		var gx = round(mouse_pos.x / TILE_SIZE)
		var gy = round(mouse_pos.y / TILE_SIZE)
		skill_preview_node.position = grid_to_local(Vector2i(gx, gy))

func _input(event):
	match interaction_state:
		STATE_SKILL_TARGETING:
			_handle_input_skill_targeting(event)
		STATE_SELECTING_INTERACTION_TARGET:
			_handle_input_interaction_selection(event)
		STATE_IDLE:
			_handle_input_idle(event)
		_:
			_handle_input_idle(event)

func _handle_input_skill_targeting(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos_global = get_global_mouse_position()
			var mouse_pos = get_local_mouse_position()
			var gx = int(round(mouse_pos.x / TILE_SIZE))
			var gy = int(round(mouse_pos.y / TILE_SIZE))

			print("[DEBUG] GridManager._input: Global Mouse: ", mouse_pos_global, " Local Mouse: ", mouse_pos, " Grid: ", gx, ",", gy)

			if skill_source_unit and is_instance_valid(skill_source_unit):
				skill_source_unit.execute_skill_at(Vector2i(gx, gy))

			exit_skill_targeting()
			get_viewport().set_input_as_handled()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			exit_skill_targeting()
			get_viewport().set_input_as_handled()

func _handle_input_interaction_selection(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_local_mouse_position()
			var gx = int(round(mouse_pos.x / TILE_SIZE))
			var gy = int(round(mouse_pos.y / TILE_SIZE))
			var grid_pos = Vector2i(gx, gy)

			if grid_pos in valid_interaction_targets:
				if interaction_source_unit and is_instance_valid(interaction_source_unit):
					interaction_source_unit.interaction_target_pos = grid_pos
					recalculate_buffs()
				end_interaction_selection()
				get_viewport().set_input_as_handled()
			else:
				# Clicked outside valid target
				# Cancel selection on invalid click as per requirements
				end_interaction_selection()
				get_viewport().set_input_as_handled()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Cancel interaction
			end_interaction_selection()
			get_viewport().set_input_as_handled()

func _handle_input_idle(event):
	# Default state handling
	# Currently logic for unit placement and clicking is handled via Tile signals or other managers
	pass

func update_placement_preview(grid_pos: Vector2i, world_pos: Vector2, item_id: String):
	if not placement_preview_cursor:
		placement_preview_cursor = Node2D.new()
		placement_preview_cursor.name = "PlacementPreviewCursor"
		var visual = ColorRect.new()
		visual.name = "Visual"
		visual.size = Vector2(TILE_SIZE, TILE_SIZE)
		visual.position = -visual.size / 2
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		placement_preview_cursor.add_child(visual)
		add_child(placement_preview_cursor)

	placement_preview_cursor.global_position = world_pos
	placement_preview_cursor.visible = true

	var is_valid = can_place_item_at(grid_pos, item_id)
	var visual = placement_preview_cursor.get_node("Visual")
	if is_valid:
		visual.color = Color(0, 1, 0, 0.4)
	else:
		visual.color = Color(1, 0, 0, 0.4)

	last_preview_frame = Engine.get_process_frames()

func can_place_item_at(grid_pos: Vector2i, item_id: String) -> bool:
	var key = get_tile_key(grid_pos.x, grid_pos.y)
	if !tiles.has(key): return false

	var tile = tiles[key]

	if "trap" in item_id or item_id == "poison_trap" or item_id == "fang_trap":
		# 1. Not on spawn tiles
		if spawn_tiles.has(grid_pos): return false
		# 2. No obstacles
		if obstacles.has(grid_pos): return false
		# 3. No units
		if tile.unit != null: return false
		if tile.occupied_by != Vector2i.ZERO: return false

		# 4. Restriction: Cannot place on Core or Unlocked Core Area
		if is_in_core_zone(grid_pos) and tile.state == "unlocked": return false

		return true

	return false

func spawn_trap_custom(grid_pos: Vector2i, type_key: String):
	var key = get_tile_key(grid_pos.x, grid_pos.y)
	if !tiles.has(key): return
	var tile = tiles[key]

	# We assume checks are done.
	_spawn_barricade(tile, type_key)

func try_spawn_trap(world_pos: Vector2, type_key: String):
	var gx = int(round(world_pos.x / TILE_SIZE))
	var gy = int(round(world_pos.y / TILE_SIZE))
	var grid_pos = Vector2i(gx, gy)
	var key = get_tile_key(gx, gy)

	if not tiles.has(key):
		return

	var tile = tiles[key]

	# Check requirements: No unit, No core, No obstacle
	if tile.unit != null: return
	if tile.occupied_by != Vector2i.ZERO: return
	if tile.type == "core": return
	if obstacles.has(grid_pos): return

	# _spawn_barricade(tile, type_key)

	# Inline spawning logic to ensure explicit implementation as requested and avoid confusion
	var data = Constants.BARRICADE_TYPES[type_key]
	var obstacle

	if BARRICADE_SCENE:
		obstacle = BARRICADE_SCENE.instantiate()
	else:
		obstacle = Node2D.new()
		obstacle.name = "Obstacle_" + type_key
		var visual = ColorRect.new()
		visual.size = Vector2(40, 40)
		visual.position = Vector2(-20, -20)
		if "color" in data:
			visual.color = data["color"]
		else:
			visual.color = Color.DARK_SLATE_GRAY
		obstacle.add_child(visual)

	add_child(obstacle)
	obstacle.position = tile.position

	if obstacle.has_method("init"):
		obstacle.init(Vector2i(tile.x, tile.y), type_key)

	register_obstacle(Vector2i(tile.x, tile.y), obstacle)

func _init_astar():
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(
		-Constants.MAP_WIDTH / 2,
		-Constants.MAP_HEIGHT / 2,
		Constants.MAP_WIDTH,
		Constants.MAP_HEIGHT
	)
	astar_grid.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER # Usually tower defense is Manhattan distance
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.update()

	if GameManager.has_signal("wave_started"):
		GameManager.wave_started.connect(func():
			expansion_mode = false
			clear_ghosts()
		)

func create_initial_grid():
	# Clear existing
	for key in tiles:
		tiles[key].queue_free()
	tiles.clear()
	spawn_tiles.clear()
	active_territory_tiles.clear()

	var half_w = Constants.MAP_WIDTH / 2
	var half_h = Constants.MAP_HEIGHT / 2

	# Determine spawn candidates (Four corners)
	var chosen_spawns = []
	var corners = [
		Vector2i(-half_w, -half_h),
		Vector2i(half_w, -half_h),
		Vector2i(-half_w, half_h),
		Vector2i(half_w, half_h)
	]

	for corner in corners:
		chosen_spawns.append(corner)
		# Determine direction towards center
		var dx = 1 if corner.x < 0 else -1
		var dy = 1 if corner.y < 0 else -1

		# Horizontal extension
		chosen_spawns.append(Vector2i(corner.x + dx, corner.y))
		chosen_spawns.append(Vector2i(corner.x + dx * 2, corner.y))

		# Vertical extension
		chosen_spawns.append(Vector2i(corner.x, corner.y + dy))
		chosen_spawns.append(Vector2i(corner.x, corner.y + dy * 2))

	for x in range(-half_w, half_w + 1):
		for y in range(-half_h, half_h + 1):
			var type = "wilderness"
			var state = "locked_inner"

			# Check Core Zone
			if abs(x) <= Constants.CORE_ZONE_RADIUS and abs(y) <= Constants.CORE_ZONE_RADIUS:
				type = "core_zone"
				state = "locked_inner"
				if x == 0 and y == 0:
					type = "core" # The absolute center
					state = "unlocked"
			else:
				type = "wilderness"
				state = "locked_outer"

			# Check Unlocked (Cross Shape)
			# (0,0) is core, unlocked. Neighbors (0,1), (0,-1), (1,0), (-1,0) are unlocked.
			if (x == 0 and y == 0) or \
			   (x == 0 and abs(y) == 1) or \
			   (y == 0 and abs(x) == 1):
				state = "unlocked"
				if type == "wilderness":
					type = "normal"
				elif type == "core_zone":
					type = "normal"
				if x == 0 and y == 0:
					type = "core"

			# Check Spawn Points
			if Vector2i(x,y) in chosen_spawns:
				state = "spawn"
				spawn_tiles.append(Vector2i(x,y))

			create_tile(x, y, type, state)

	print("Total Spawn Tiles: ", spawn_tiles.size())

func create_tile(x: int, y: int, type: String = "normal", state: String = "locked_inner"):
	var key = get_tile_key(x, y)
	if tiles.has(key): return

	var tile = TILE_SCENE.instantiate()
	tile.setup(x, y, type)
	# Explicitly call set_state to ensure visuals are updated
	tile.set_state(state)

	tile.position = grid_to_local(Vector2i(x, y))
	add_child(tile)
	tiles[key] = tile

	if state == "unlocked" or type == "core":
		if not active_territory_tiles.has(tile):
			active_territory_tiles.append(tile)

	tile.tile_clicked.connect(_on_tile_clicked)

	# Initial weight setup for AStar
	var grid_pos = Vector2i(x, y)
	if astar_grid.is_in_boundsv(grid_pos):
		# Assuming obstacles and locked tiles affect navigation?
		# For now standard weight, obstacles will increase it.
		astar_grid.set_point_weight_scale(grid_pos, 1.0)

func _generate_random_obstacles():
	var candidate_tiles = []
	for key in tiles:
		var tile = tiles[key]
		# Candidates: locked_outer, not spawn, not core_zone (implied by locked_outer check in create_initial_grid logic, but let's be safe)
		if tile.state == "locked_outer":
			candidate_tiles.append(tile)

	# Generate 10-15 obstacles
	var obstacle_count = randi_range(10, 15)
	obstacle_count = min(obstacle_count, candidate_tiles.size())
	candidate_tiles.shuffle()

	var placed_count = 0
	for i in range(candidate_tiles.size()):
		if placed_count >= obstacle_count: break

		var tile = candidate_tiles[i]

		# Pick random type
		var type_keys = Constants.BARRICADE_TYPES.keys()
		var type_key = type_keys.pick_random()

		_spawn_barricade(tile, type_key)

		# Check connectivity
		if not is_path_clear_from_spawns_to_core():
			# Undo
			var grid_pos = Vector2i(tile.x, tile.y)
			var obstacle = obstacles[grid_pos]
			remove_obstacle(obstacle)
			obstacle.queue_free()
		else:
			placed_count += 1

func is_path_clear_from_spawns_to_core() -> bool:
	var core_pos = Vector2i(0, 0) # Assumes core is at 0,0

	# If core itself is blocked (shouldn't happen logic wise but safe to check)
	if obstacles.has(core_pos): return false

	for spawn_pos in spawn_tiles:
		# astar_grid.get_id_path returns Array[Vector2i]
		var path = astar_grid.get_id_path(spawn_pos, core_pos)
		if path.size() == 0:
			return false
	return true

func _spawn_barricade(tile, type_key):
	var data = Constants.BARRICADE_TYPES[type_key]
	var obstacle

	if BARRICADE_SCENE:
		obstacle = BARRICADE_SCENE.instantiate()
	else:
		obstacle = Node2D.new()
		obstacle.name = "Obstacle_" + type_key
		var visual = ColorRect.new()
		visual.size = Vector2(40, 40)
		visual.position = Vector2(-20, -20)
		if "color" in data:
			visual.color = data["color"]
		else:
			visual.color = Color.DARK_SLATE_GRAY
		obstacle.add_child(visual)

	add_child(obstacle)
	obstacle.position = tile.position

	if obstacle.has_method("init"):
		obstacle.init(Vector2i(tile.x, tile.y), type_key)

	register_obstacle(Vector2i(tile.x, tile.y), obstacle)


func register_obstacle(grid_pos: Vector2i, node: Node):
	if astar_grid.is_in_boundsv(grid_pos):
		# Ensure obstacle is always passable for pathfinding
		astar_grid.set_point_solid(grid_pos, false)
		astar_grid.set_point_weight_scale(grid_pos, 1.0)

	# Map the node to the grid position for later removal
	obstacle_map[node] = grid_pos
	# Add to fast lookup for placement checks
	obstacles[grid_pos] = node

func remove_obstacle(node: Node):
	if not obstacle_map.has(node):
		return

	var grid_pos = obstacle_map[node]
	# Removed AStar reset logic as obstacles no longer block pathfinding

	obstacles.erase(grid_pos)
	obstacle_map.erase(node)

func get_nav_path(start_pos: Vector2, end_pos: Vector2) -> PackedVector2Array:
	var start_grid = Vector2i(round(start_pos.x / TILE_SIZE), round(start_pos.y / TILE_SIZE))
	var end_grid = Vector2i(round(end_pos.x / TILE_SIZE), round(end_pos.y / TILE_SIZE))

	if not astar_grid.is_in_boundsv(start_grid) or not astar_grid.is_in_boundsv(end_grid):
		return PackedVector2Array()

	return astar_grid.get_point_path(start_grid, end_grid)

func get_spawn_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for tile_pos in spawn_tiles:
		# Use grid_to_local
		var local_pos = grid_to_local(tile_pos)
		points.append(to_global(local_pos))
	return points

func get_tile_key(x: int, y: int) -> String:
	return "%d,%d" % [x, y]

func get_world_pos_from_grid(grid_pos: Vector2i) -> Vector2:
	return to_global(grid_to_local(grid_pos))

# --- Unit Logic ---

func place_unit(unit_key: String, x: int, y: int) -> bool:
	var key = get_tile_key(x, y)
	if !tiles.has(key): return false

	var tile = tiles[key]
	if tile.unit != null or tile.occupied_by != Vector2i.ZERO: return false

	var unit = UNIT_SCENE.instantiate()
	unit.setup(unit_key)

	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	if !can_place_unit(x, y, w, h):
		unit.queue_free()
		return false

	add_child(unit)
	# unit.position = tile.position + Vector2((w-1) * TILE_SIZE * 0.5, (h-1) * TILE_SIZE * 0.5)
	# tile.position is already derived from grid_to_local(x,y).
	# We can use grid_to_local directly on the tile, but tile.position is fine.
	# To stay consistent with "using grid_to_local in place_unit", we can do:
	unit.position = grid_to_local(Vector2i(x,y)) + Vector2((w-1) * TILE_SIZE * 0.5, (h-1) * TILE_SIZE * 0.5)

	unit.start_position = unit.position
	unit.grid_pos = Vector2i(x, y)

	_set_tiles_occupied(x, y, w, h, unit)

	# Register as obstacle if it's a defensive unit
	if unit.unit_data.get("trait") in ["reflect", "flat_reduce"]:
		register_obstacle(Vector2i(x, y), unit)

	recalculate_buffs()
	GameManager.recalculate_max_health()

	# Check for Interaction
	var info = unit.get_interaction_info()
	if info.has_interaction:
		start_interaction_selection(unit)

	return true

func _set_tiles_occupied(x: int, y: int, w: int, h: int, unit):
	for dx in range(w):
		for dy in range(h):
			var t_key = get_tile_key(x + dx, y + dy)
			if tiles.has(t_key):
				var t = tiles[t_key]
				if dx == 0 and dy == 0:
					t.unit = unit
				else:
					t.occupied_by = Vector2i(x, y)

func _clear_tiles_occupied(x: int, y: int, w: int, h: int):
	for dx in range(w):
		for dy in range(h):
			var t_key = get_tile_key(x + dx, y + dy)
			if tiles.has(t_key):
				var t = tiles[t_key]
				t.unit = null
				t.occupied_by = Vector2i.ZERO

func is_in_core_zone(pos: Vector2i) -> bool:
	return abs(pos.x) <= Constants.CORE_ZONE_RADIUS and abs(pos.y) <= Constants.CORE_ZONE_RADIUS

# --- Skill Targeting ---

func enter_skill_targeting(unit: Node2D):
	exit_skill_targeting() # Cleanup if already active

	interaction_state = STATE_SKILL_TARGETING
	skill_source_unit = unit

	skill_preview_node = Node2D.new()
	skill_preview_node.name = "SkillPreview"
	skill_preview_node.z_index = 100

	# Create 3x3 highlight
	for x in range(-1, 2):
		for y in range(-1, 2):
			var rect = ColorRect.new()
			rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			# Replaced manual Vector2 calculation with grid_to_local logic offset?
			# Or just utilize TILE_SIZE. grid_to_local is for grid coordinates (integers).
			# Here we are drawing relative to (0,0) of the preview node.
			# But the preview node position is set using grid_to_local in _process.
			# So local children offsets are fine to use TILE_SIZE directly.
			rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE) - Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0)
			rect.color = Color(0, 1, 0, 0.4)
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			skill_preview_node.add_child(rect)

	add_child(skill_preview_node)

func exit_skill_targeting():
	if skill_preview_node:
		skill_preview_node.queue_free()
		skill_preview_node = null

	interaction_state = STATE_IDLE
	skill_source_unit = null

# --- Interaction System Implementation ---

func is_neighbor(unit, target_pos: Vector2i) -> bool:
	var cx = unit.grid_pos.x
	var cy = unit.grid_pos.y
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	# Check if target_pos is adjacent to the rectangle defined by (cx, cy, w, h)
	if target_pos.x >= cx - 1 and target_pos.x < cx + w + 1:
		if target_pos.y >= cy - 1 and target_pos.y < cy + h + 1:
			# It is in the expanded box. Now check if it is NOT inside the unit.
			if target_pos.x >= cx and target_pos.x < cx + w and target_pos.y >= cy and target_pos.y < cy + h:
				return false # Inside
			return true
	return false

func start_interaction_selection(unit):
	interaction_state = STATE_SELECTING_INTERACTION_TARGET
	interaction_source_unit = unit
	valid_interaction_targets.clear()

	# Calculate neighbors (8 directions)
	var cx = unit.grid_pos.x
	var cy = unit.grid_pos.y

	var neighbors = []
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	# Top and Bottom rows
	for dx in range(-1, w + 1):
		neighbors.append(Vector2i(cx + dx, cy - 1))
		neighbors.append(Vector2i(cx + dx, cy + h))

	# Left and Right columns (excluding corners already added)
	for dy in range(0, h):
		neighbors.append(Vector2i(cx - 1, cy + dy))
		neighbors.append(Vector2i(cx + w, cy + dy))

	for pos in neighbors:
		if is_valid_interaction_target(unit, pos):
			valid_interaction_targets.append(pos)
			var color = Color.GREEN
			if unit.unit_data.get("buff_id") == "multishot":
				color = Color(0, 1, 1, 0.4)
			_spawn_interaction_highlight(pos, color)
		else:
			_spawn_interaction_highlight(pos, Color.RED)

	# Pause game or just block input?
	# "Place -> Pause -> Select Neighbor -> Effect"
	# Ideally we set time scale to 0 or block other inputs.
	# For this task, visual feedback + state lock is sufficient unless explicit pause requested.
	# Assuming realtime continues but input is hijacked.

func is_valid_interaction_target(origin_unit, target_pos: Vector2i) -> bool:
	var key = get_tile_key(target_pos.x, target_pos.y)
	if !tiles.has(key): return false
	var tile = tiles[key]

	# Rule: Neighbor + In Core Zone + Unlocked
	if !is_in_core_zone(target_pos): return false
	if tile.state != "unlocked" and tile.type != "core": return false # Core is unlocked by definition usually

	return true

func end_interaction_selection():
	interaction_state = STATE_IDLE
	interaction_source_unit = null
	valid_interaction_targets.clear()
	for node in interaction_highlights:
		node.queue_free()
	interaction_highlights.clear()
	selection_overlay.queue_redraw()

func _spawn_interaction_highlight(grid_pos: Vector2i, color: Color = Color(1, 0.84, 0, 0.4)):
	var highlight = ColorRect.new()
	highlight.size = Vector2(TILE_SIZE, TILE_SIZE)
	highlight.color = color
	highlight.color.a = 0.4 # Ensure transparency

	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(highlight)

	# Use grid_to_local
	var local_pos = grid_to_local(grid_pos)
	highlight.position = local_pos - Vector2(TILE_SIZE, TILE_SIZE) / 2
	interaction_highlights.append(highlight)

func _on_selection_overlay_draw():
	if interaction_state == STATE_SELECTING_INTERACTION_TARGET and interaction_source_unit and is_instance_valid(interaction_source_unit):
		var start_pos = interaction_source_unit.global_position
		var end_pos = get_global_mouse_position()

		# Convert to local coordinates relative to Overlay (which is same as GridManager global effectively if no offset, but Node2D children follow parent transform)
		start_pos = selection_overlay.to_local(start_pos)
		end_pos = selection_overlay.to_local(end_pos)

		var control_point = (start_pos + end_pos) / 2
		control_point.y -= 50

		var segments = 20
		var curve_points = PackedVector2Array()
		for i in range(segments + 1):
			var t = float(i) / segments
			var q0 = start_pos.lerp(control_point, t)
			var q1 = control_point.lerp(end_pos, t)
			var p = q0.lerp(q1, t)
			curve_points.append(p)

		# Arrow Calculation
		var arrow_len = 15.0
		var direction = Vector2.RIGHT
		if curve_points.size() >= 2:
			direction = (curve_points[-1] - curve_points[-2]).normalized()
		else:
			direction = (end_pos - control_point).normalized()

		# Trim the line so it doesn't overlap the arrow tip area too much
		var trimmed_points = PackedVector2Array()
		var arrow_base_center = end_pos - direction * (arrow_len * 0.5)
		# Or just draw line to end_pos and draw arrow on top.
		# If user says arrow is "behind", maybe they mean the line goes OVER the arrow?
		# Drawing order: Line first, then Arrow. The Arrow should cover the line.
		# Let's ensure Arrow is big enough and centered at end_pos.

		# Arrow Vertices: Tip at end_pos
		var arrow_tip = end_pos
		var arrow_back = end_pos - direction * arrow_len
		var arrow_side1 = arrow_back + direction.orthogonal() * (arrow_len * 0.5)
		var arrow_side2 = arrow_back - direction.orthogonal() * (arrow_len * 0.5)

		# Draw Line
		# To avoid glitch, we can trim the line to arrow_back
		var line_end_idx = segments
		# Simple distance check to find where to cut?
		# Just modifying the last point to be arrow_back might be enough if segments are small.
		if curve_points.size() > 1:
			curve_points[-1] = arrow_back

		selection_overlay.draw_polyline(curve_points, Color.WHITE, 3.0, true)
		selection_overlay.draw_colored_polygon(PackedVector2Array([arrow_tip, arrow_side1, arrow_side2]), Color.WHITE)

func can_place_unit(x: int, y: int, w: int, h: int, exclude_unit = null) -> bool:
	for dx in range(w):
		for dy in range(h):
			var pos = Vector2i(x + dx, y + dy)
			var key = get_tile_key(x + dx, y + dy)
			if !tiles.has(key): return false
			var tile = tiles[key]
			if tile.state != "unlocked": return false
			if tile.type == "core": return false
			if tile.unit and tile.unit != exclude_unit: return false
			if obstacles.has(pos): return false
			if tile.occupied_by != Vector2i.ZERO:
				if exclude_unit and tile.occupied_by == exclude_unit.grid_pos:
					continue
				return false
	return true

func _on_tile_clicked(tile):
	if GameManager.is_wave_active: return
	# print("Clicked tile: ", tile.x, ",", tile.y)

func remove_unit_from_grid(unit):
	if unit == null: return
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	if unit.unit_data.get("trait") in ["reflect", "flat_reduce"]:
		remove_obstacle(unit)

	_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
	unit.queue_free()
	recalculate_buffs()
	GameManager.recalculate_max_health()

# Drag and Drop Implementation
func handle_bench_drop_at(target_tile, data):
	var unit_key = data.key
	var bench_index = data.index

	# Try to place
	if place_unit(unit_key, target_tile.x, target_tile.y):
		# Success, remove from bench
		if GameManager.main_game:
			GameManager.main_game.remove_from_bench(bench_index)
		else:
			print("GridManager: GameManager.main_game is null during bench drop!")
		return

	# If place_unit failed, check for interactions (Devour/Merge)
	var target_unit = target_tile.unit
	if target_unit == null and target_tile.occupied_by != Vector2i.ZERO:
		var origin_key = get_tile_key(target_tile.occupied_by.x, target_tile.occupied_by.y)
		if tiles.has(origin_key):
			target_unit = tiles[origin_key].unit

	if target_unit:
		# Create a temporary unit to pass to interactions
		var temp_unit = UNIT_SCENE.instantiate()
		temp_unit.setup(unit_key)

		# Check Merge
		if target_unit.can_merge_with(temp_unit):
			target_unit.merge_with(temp_unit)
			if GameManager.main_game:
				GameManager.main_game.remove_from_bench(bench_index)
			recalculate_buffs()
			temp_unit.queue_free()
			GameManager.recalculate_max_health()
			return

		# Check Devour
		if can_devour(target_unit, temp_unit):
			target_unit.devour(temp_unit)
			if GameManager.main_game:
				GameManager.main_game.remove_from_bench(bench_index)
			recalculate_buffs()
			temp_unit.queue_free()
			GameManager.recalculate_max_health()
			return

		temp_unit.queue_free()

func handle_grid_move_at(target_tile, data):
	var unit = data.unit
	if !unit: return

	try_move_unit(unit, tiles[get_tile_key(unit.grid_pos.x, unit.grid_pos.y)], target_tile)

func try_move_unit(unit, from_tile, to_tile) -> bool:
	if unit == null or from_tile == null or to_tile == null: return false
	if from_tile == to_tile: return true

	var x = to_tile.x
	var y = to_tile.y
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y

	# Case 1: Empty Target
	if can_place_unit(x, y, w, h, unit):
		_move_unit_internal(unit, x, y)
		return true

	# Case 2: Interaction (Merge, Devour, Swap)
	var target_unit = to_tile.unit
	if target_unit == null and to_tile.occupied_by != Vector2i.ZERO:
		var origin_key = get_tile_key(to_tile.occupied_by.x, to_tile.occupied_by.y)
		if tiles.has(origin_key):
			target_unit = tiles[origin_key].unit

	if target_unit == null: return false
	if target_unit == unit: return false

	if target_unit.can_merge_with(unit):
		target_unit.merge_with(unit)
		_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
		unit.queue_free()
		recalculate_buffs()
		return true

	if can_devour(target_unit, unit):
		target_unit.devour(unit)
		_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
		unit.queue_free()
		recalculate_buffs()
		return true

	if can_swap(unit, target_unit):
		_perform_swap(unit, target_unit)
		return true

	return false

func _move_unit_internal(unit, new_x, new_y):
	var w = unit.unit_data.size.x
	var h = unit.unit_data.size.y
	_clear_tiles_occupied(unit.grid_pos.x, unit.grid_pos.y, w, h)
	unit.grid_pos = Vector2i(new_x, new_y)
	_set_tiles_occupied(new_x, new_y, w, h, unit)

	var tile = tiles[get_tile_key(new_x, new_y)]
	# Use grid_to_local for unit position update
	unit.position = grid_to_local(Vector2i(new_x, new_y)) + Vector2((w-1) * TILE_SIZE * 0.5, (h-1) * TILE_SIZE * 0.5)

	unit.start_position = unit.position

	# Clear old interaction target when moved
	unit.interaction_target_pos = null

	recalculate_buffs()

	# Trigger new selection if needed
	var info = unit.get_interaction_info()
	if info.has_interaction:
		start_interaction_selection(unit)

func can_devour(eater, food) -> bool:
	if food.unit_data.has("isFood") and food.unit_data.isFood:
		return true
	return false

func can_swap(unit_a, unit_b) -> bool:
	var pos_a = unit_a.grid_pos
	var size_a = unit_a.unit_data.size
	var pos_b = unit_b.grid_pos
	var size_b = unit_b.unit_data.size

	if size_a == size_b: return true
	if !can_place_unit_custom(pos_b.x, pos_b.y, size_a.x, size_a.y, [unit_a, unit_b]): return false
	if !can_place_unit_custom(pos_a.x, pos_a.y, size_b.x, size_b.y, [unit_a, unit_b]): return false
	return true

func can_place_unit_custom(x: int, y: int, w: int, h: int, ignore_units: Array) -> bool:
	for dx in range(w):
		for dy in range(h):
			var key = get_tile_key(x + dx, y + dy)
			if !tiles.has(key): return false
			var tile = tiles[key]
			if tile.type == "core": return false
			if tile.unit and not (tile.unit in ignore_units): return false
			if tile.occupied_by != Vector2i.ZERO:
				var origin_key = get_tile_key(tile.occupied_by.x, tile.occupied_by.y)
				if tiles.has(origin_key):
					var occupant = tiles[origin_key].unit
					if occupant and not (occupant in ignore_units):
						return false
	return true

func _perform_swap(unit_a, unit_b):
	var pos_a = unit_a.grid_pos
	var pos_b = unit_b.grid_pos
	var size_a = unit_a.unit_data.size
	var size_b = unit_b.unit_data.size

	_clear_tiles_occupied(pos_a.x, pos_a.y, size_a.x, size_a.y)
	_clear_tiles_occupied(pos_b.x, pos_b.y, size_b.x, size_b.y)

	unit_a.grid_pos = pos_b
	_set_tiles_occupied(pos_b.x, pos_b.y, size_a.x, size_a.y, unit_a)

	unit_b.grid_pos = pos_a
	_set_tiles_occupied(pos_a.x, pos_a.y, size_b.x, size_b.y, unit_b)

	var tile_for_a = tiles[get_tile_key(pos_b.x, pos_b.y)]
	unit_a.position = tile_for_a.position + Vector2((size_a.x-1) * TILE_SIZE * 0.5, (size_a.y-1) * TILE_SIZE * 0.5)
	unit_a.start_position = unit_a.position

	var tile_for_b = tiles[get_tile_key(pos_a.x, pos_a.y)]
	unit_b.position = tile_for_b.position + Vector2((size_b.x-1) * TILE_SIZE * 0.5, (size_b.y-1) * TILE_SIZE * 0.5)
	unit_b.start_position = unit_b.position

	recalculate_buffs()

func recalculate_buffs():
	var processed_units = []
	for key in tiles:
		var tile = tiles[key]
		if tile.unit and not (tile.unit in processed_units):
			tile.unit.reset_stats()
			processed_units.append(tile.unit)

	for unit in processed_units:
		if "buffProvider" in unit.unit_data:
			var buff_type = unit.unit_data["buffProvider"]
			_apply_buff_to_neighbors(unit, buff_type)

		# Parrot Range Update
		if unit.type_key == "parrot":
			unit.update_parrot_range()

		# Interaction Buffs
		var info = unit.get_interaction_info()
		if info.has_interaction and unit.interaction_target_pos != null:
			if is_neighbor(unit, unit.interaction_target_pos):
				_apply_buff_to_specific_pos(unit.interaction_target_pos, info.buff_id, unit)

	for unit in processed_units:
		unit.update_visuals()

	grid_updated.emit()

func _apply_buff_to_specific_pos(target_pos: Vector2i, buff_id: String, provider_unit: Node2D = null):
	var key = get_tile_key(target_pos.x, target_pos.y)
	if tiles.has(key):
		var tile = tiles[key]
		var target_unit = tile.unit
		# Handle occupied_by if needed (though usually we buff the main unit)
		if target_unit == null and tile.occupied_by != Vector2i.ZERO:
			var origin_key = get_tile_key(tile.occupied_by.x, tile.occupied_by.y)
			if tiles.has(origin_key):
				target_unit = tiles[origin_key].unit

		if target_unit:
			target_unit.apply_buff(buff_id, provider_unit)

func _apply_buff_to_neighbors(provider_unit, buff_type):
	var cx = provider_unit.grid_pos.x
	var cy = provider_unit.grid_pos.y
	var w = provider_unit.unit_data.size.x
	var h = provider_unit.unit_data.size.y
	var neighbors = []

	for dx in range(w):
		neighbors.append(Vector2i(cx + dx, cy - 1))
		neighbors.append(Vector2i(cx + dx, cy + h))

	for dy in range(h):
		neighbors.append(Vector2i(cx - 1, cy + dy))
		neighbors.append(Vector2i(cx + w, cy + dy))

	for n_pos in neighbors:
		var n_key = get_tile_key(n_pos.x, n_pos.y)
		if tiles.has(n_key):
			var tile = tiles[n_key]
			var target_unit = tile.unit
			if target_unit == null and tile.occupied_by != Vector2i.ZERO:
				var origin_key = get_tile_key(tile.occupied_by.x, tile.occupied_by.y)
				if tiles.has(origin_key):
					target_unit = tiles[origin_key].unit
			if target_unit and target_unit != provider_unit:
				target_unit.apply_buff(buff_type, provider_unit)

func toggle_expansion_mode():
	expansion_mode = !expansion_mode

	# Toggle grid lines on all tiles
	for key in tiles:
		if tiles[key].has_method("set_grid_visible"):
			tiles[key].set_grid_visible(expansion_mode)

	if expansion_mode:
		spawn_expansion_ghosts()
	else:
		clear_ghosts()

func spawn_expansion_ghosts():
	clear_ghosts()

	for key in tiles:
		var tile = tiles[key]

		# Limit expansion ghost tiles to center 5x5 area (plus minus 2 from center)
		if abs(tile.x) > 2 or abs(tile.y) > 2:
			continue

		# Find locked tiles that can be unlocked
		if tile.state == "locked_inner" or tile.state == "locked_outer":
			# Check neighbors
			var x = tile.x
			var y = tile.y
			var neighbors = [
				Vector2i(x+1, y), Vector2i(x-1, y),
				Vector2i(x, y+1), Vector2i(x, y-1)
			]

			var can_expand = false
			for n_pos in neighbors:
				var n_key = get_tile_key(n_pos.x, n_pos.y)
				if tiles.has(n_key):
					var n_tile = tiles[n_key]
					# If neighbor is unlocked or core (which is unlocked), we can expand
					if n_tile.state == "unlocked":
						can_expand = true
						break

			if can_expand:
				var ghost = GHOST_TILE_SCRIPT.new()
				add_child(ghost)
				ghost.setup(tile.x, tile.y)

				# Use grid_to_local for ghost position
				var local_pos = grid_to_local(Vector2i(tile.x, tile.y))
				ghost.position = local_pos - (ghost.custom_minimum_size / 2)

				# ghost.clicked.connect(on_ghost_clicked) # GhostTile calls grid_manager.on_ghost_clicked directly
				ghost_tiles.append(ghost)

func clear_ghosts():
	for ghost in ghost_tiles:
		ghost.queue_free()
	ghost_tiles.clear()

func on_ghost_clicked(x, y):
	var cost = expansion_cost
	if GameManager.reward_manager and "rapid_expansion" in GameManager.reward_manager.acquired_artifacts:
		cost = int(cost * 0.7)

	if GameManager.gold >= cost:
		if GameManager.spend_gold(cost):
			expansion_cost += 10
			var key = get_tile_key(x, y)
			if tiles.has(key):
				var tile = tiles[key]
				tile.set_state("unlocked")
				if not active_territory_tiles.has(tile):
					active_territory_tiles.append(tile)

				# Artifact: Rapid Expansion Bonus
				if GameManager.reward_manager and "rapid_expansion" in GameManager.reward_manager.acquired_artifacts:
					GameManager.permanent_health_bonus += 50.0
					GameManager.max_core_health += 50.0
					GameManager.core_health += 50.0 # Heal by the added amount
					GameManager.resource_changed.emit()

			# Refresh ghosts to show new expansion options
			# Must use call_deferred or just call it?
			# The prompt says: "call clear_ghosts() then immediately re-spawn_expansion_ghosts()"
			clear_ghosts()
			spawn_expansion_ghosts()
	else:
		# Feedback for not enough gold?
		# Use grid_to_local
		var world_pos = get_world_pos_from_grid(Vector2i(x,y))
		GameManager.spawn_floating_text(world_pos, "Need Gold!", Color.RED)

func get_closest_unlocked_tile(world_pos: Vector2) -> Node2D:
	if active_territory_tiles.is_empty():
		# Fallback to core if exists
		var core_key = get_tile_key(0, 0)
		if tiles.has(core_key):
			return tiles[core_key]
		return null

	var closest_tile = null
	var min_dist_sq = INF

	for tile in active_territory_tiles:
		# Check if valid instance
		if not is_instance_valid(tile): continue

		var dist_sq = tile.global_position.distance_squared_to(world_pos)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest_tile = tile

	return closest_tile

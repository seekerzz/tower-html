extends PanelContainer

@onready var title_label = $VBoxContainer/TitleLabel
@onready var stats_label = $VBoxContainer/StatsLabel
@onready var buff_label = $VBoxContainer/BuffLabel

func _ready():
	hide()

func show_tooltip(unit_data: Dictionary, current_stats: Dictionary, active_buffs: Array, global_pos: Vector2):
	title_label.text = "[b]" + unit_data.get("icon", "") + " " + unit_data.get("name", "Unknown") + "[/b]"

	var desc = unit_data.get("desc", "")
	var stats_text = ""
	var level = current_stats.get("level", 1)
	stats_text += "Level: %d\n" % level
	stats_text += "Damage: %d\n" % floor(current_stats.get("damage", 0))
	stats_text += "Range: %d\n" % floor(current_stats.get("range", 0))
	stats_text += "Speed: %.2f\n" % current_stats.get("atk_speed", 0)

	if desc != "":
		stats_text += "\n[color=#aaaaaa]" + desc + "[/color]"

	stats_label.text = stats_text

	var buff_text = ""
	if active_buffs.size() > 0:
		buff_text = "[color=yellow]Buffs:[/color]\n"
		for b in active_buffs:
			buff_text += "- " + b.capitalize() + "\n"

	buff_label.text = buff_text
	buff_label.visible = active_buffs.size() > 0

	# Positioning
	# Move to mouse position but keep within screen

	# Force update layout to get accurate size
	# reset_size() alone might set it to min_size which could be (0,0) or (1, huge) if constraints are odd.
	# We rely on existing min width or set one.
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(200, 0) # Enforce a minimum width so text doesn't wrap to infinity

	reset_size()

	var vp_size = get_viewport_rect().size
	var size = get_size()
	# print("Debug Tooltip: vp_size=", vp_size, " size=", size, " global_pos=", global_pos)
	var target_pos = global_pos + Vector2(20, 20)

	# Boundary checks
	if target_pos.x + size.x > vp_size.x:
		target_pos.x = global_pos.x - size.x - 20

	if target_pos.y + size.y > vp_size.y:
		target_pos.y = global_pos.y - size.y - 20

	# Clamp to ensure it doesn't go off-screen top/left
	target_pos.x = max(0, target_pos.x)
	target_pos.y = max(0, target_pos.y)

	position = target_pos

	show()
	z_index = 4096 # On top

func hide_tooltip():
	hide()

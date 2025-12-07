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
	position = global_pos + Vector2(20, 20)

	show()
	z_index = 4096 # On top

func hide_tooltip():
	hide()

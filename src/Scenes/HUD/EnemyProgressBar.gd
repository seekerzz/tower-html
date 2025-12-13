extends Control

@onready var progress_bar = $ProgressBar
@onready var label = $ProgressBar/Label

func _ready():
	hide()
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_ended.connect(_on_wave_ended)

	_setup_style()

func _process(_delta):
	if visible:
		_update_progress()

func _update_progress():
	if GameManager.is_wave_active and GameManager.combat_manager:
		var total = GameManager.combat_manager.total_enemies_for_wave
		var alive = get_tree().get_nodes_in_group("enemies").size()
		var to_spawn = GameManager.combat_manager.enemies_to_spawn
		var current_alive = alive + to_spawn

		if total > 0:
			progress_bar.max_value = total
			progress_bar.value = current_alive
			label.text = "%d / %d" % [current_alive, total]
		else:
			label.text = "0 / 0"

func _on_wave_started():
	show()

func _on_wave_ended():
	hide()

func _setup_style():
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg_style.set_corner_radius_all(6)
	bg_style.border_width_bottom = 2
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_color = Color.BLACK

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.6, 0.2, 0.8) # Purple
	fill_style.set_corner_radius_all(6)
	fill_style.border_width_bottom = 2
	fill_style.border_width_left = 2
	fill_style.border_width_right = 2
	fill_style.border_width_top = 2
	fill_style.border_color = Color.TRANSPARENT # Or black if we want inner border

	progress_bar.add_theme_stylebox_override("background", bg_style)
	progress_bar.add_theme_stylebox_override("fill", fill_style)

	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)

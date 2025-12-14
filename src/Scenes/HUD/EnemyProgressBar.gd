extends MarginContainer

@onready var icon_label = $HBoxContainer/IconLabel
@onready var progress_bar = $HBoxContainer/ProgressBar
@onready var label = $HBoxContainer/ProgressBar/Label
@onready var wave_info_label = $HBoxContainer/WaveInfoLabel

func _process(delta):
	if GameManager.is_wave_active:
		visible = true
		if GameManager.combat_manager:
			var total = GameManager.combat_manager.total_enemies_for_wave
			var to_spawn = GameManager.combat_manager.enemies_to_spawn
			var active = get_tree().get_nodes_in_group("enemies").size()
			var alive_or_pending = to_spawn + active
			var killed = max(0, total - alive_or_pending)

			if wave_info_label:
				# Show Wave and Enemy count (Remaining or Total)
				# Request said: "Wave X | Enemy: Y/Z"
				# Usually Y is current/killed and Z is total. Or Y is remaining.
				# Progress bar shows Killed / Total.
				# Let's make label show "Wave X | Enemies: Killed/Total" to match progress bar info context.
				wave_info_label.text = "Wave %d | Enemies: %d/%d" % [GameManager.wave, killed, total]

			if total > 0:
				var progress = float(killed) / float(total) * 100
				progress_bar.value = progress
				label.text = "%d / %d" % [killed, total]
			else:
				progress_bar.value = 100
				label.text = "Wave Clear"
	else:
		visible = false

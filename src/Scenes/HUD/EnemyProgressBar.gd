extends MarginContainer

@onready var wave_label = $HBoxContainer/WaveLabel
@onready var icon_label = $HBoxContainer/IconLabel
@onready var progress_bar = $HBoxContainer/ProgressBar
@onready var label = $HBoxContainer/ProgressBar/Label

func _process(delta):
	if GameManager.is_wave_active:
		visible = true
		if GameManager.combat_manager:
			var total = GameManager.combat_manager.total_enemies_for_wave
			# There is no 'enemies_killed' in CombatManager. We need to calculate it or check active enemies.
			# But CombatManager has 'enemies_to_spawn' which decreases.
			# And we can count active enemies in group "enemies".
			# Killed = Total - (ToSpawn + Active)

			var to_spawn = GameManager.combat_manager.enemies_to_spawn
			var active = get_tree().get_nodes_in_group("enemies").size()

			# If wave just started, to_spawn is total, active is 0. Killed = 0.
			# If wave ending, to_spawn is 0, active is 0. Killed = Total.

			var alive_or_pending = to_spawn + active
			var killed = max(0, total - alive_or_pending)

			wave_label.text = "Wave %d" % GameManager.wave

			if total > 0:
				var progress = float(killed) / float(total) * 100
				progress_bar.value = progress
				label.text = "Enemies: %d / %d" % [killed, total]
			else:
				progress_bar.value = 100
				label.text = "Wave Clear"
	else:
		visible = false

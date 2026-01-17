extends CoreMechanic

var hit_count: int = 0
var timer: Timer

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	timer = Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()

func on_core_damaged(amount: float):
	hit_count += 1

func _on_timer_timeout():
	var damage = hit_count * 5.0
	if damage > 0:
		if GameManager.combat_manager:
			# Function will be added to CombatManager
			if GameManager.combat_manager.has_method("deal_global_damage"):
				GameManager.combat_manager.deal_global_damage(damage, "magic")

		# Visual feedback
		GameManager.trigger_impact(Vector2.UP, 1.0)
		GameManager.spawn_floating_text(Vector2(0, -100), "COW REVENGE!", Color.RED)

		hit_count = 0

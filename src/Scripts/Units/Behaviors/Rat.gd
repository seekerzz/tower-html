extends UnitBehavior

const PLAGUE_DURATION = 4.0

func _init(u: Node2D):
	super._init(u)

func on_projectile_hit(target: Node2D, damage: float, projectile: Node2D):
	# Assuming target is an Enemy
	if not target.is_in_group("enemies"): return

	# Mark the enemy with a plague timestamp
	# Using Time.get_ticks_msec() for relative timing (assuming reasonable timescale behavior or short duration)
	# A more robust way would be attaching a timer, but this is lightweight.
	# We store the game time at hit. To handle time scale properly, we could use a SceneTreeTimer for cleanup
	# but we need to check "if died within 4s".

	# Let's use a unique ID for the mark to handle re-application and expiration
	var mark_id = Time.get_ticks_msec() + randi()
	target.set_meta("rat_plague_id", mark_id)
	target.set_meta("rat_plague_owner", unit)

	# Create a timer that will expire the mark
	var timer = unit.get_tree().create_timer(PLAGUE_DURATION, false)
	timer.timeout.connect(func():
		if is_instance_valid(target) and target.has_meta("rat_plague_id"):
			if target.get_meta("rat_plague_id") == mark_id:
				target.remove_meta("rat_plague_id")
				target.remove_meta("rat_plague_owner")
	)

	if not target.is_connected("died", _on_target_died):
		target.died.connect(_on_target_died.bind(target))

func on_kill(victim: Node2D):
	# Trigger spread on immediate kill
	if victim.has_meta("rat_plague_triggered"): return
	victim.set_meta("rat_plague_triggered", true)

	_spread_plague(victim.global_position)

func _on_target_died(enemy):
	# Check if marked by THIS unit
	if not enemy.has_meta("rat_plague_id"): return
	if not enemy.has_meta("rat_plague_owner"): return

	var owner_unit = enemy.get_meta("rat_plague_owner")
	if owner_unit != unit: return

	# Prevent double trigger if on_kill already handled it?
	# If delayed kill, on_kill is also called?
	# Yes, if this unit dealt the killing blow.
	# If ANOTHER unit killed it, on_kill is not called on this unit, but signal fires.
	# If THIS unit killed it (delayed), both fire.
	# We need a flag to prevent double spread.

	if enemy.has_meta("rat_plague_triggered"): return
	enemy.set_meta("rat_plague_triggered", true)

	_spread_plague(enemy.global_position)

func _spread_plague(center_pos: Vector2):
	var spread_radius = 150.0
	var level = unit.level

	var poison_stacks = 2
	if level >= 2:
		poison_stacks = 4

	var enemies = unit.get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		if enemy.global_position.distance_to(center_pos) <= spread_radius:
			enemy.add_poison_stacks(poison_stacks)

			if level >= 3:
				_apply_random_debuff(enemy)

	print("[Rat] Plague spread from death at ", center_pos, " Stacks: ", poison_stacks, " Level: ", level)

func _apply_random_debuff(enemy):
	var debuffs = ["burn", "slow", "bleed"]
	var choice = debuffs.pick_random()
	enemy.apply_debuff(choice, 1)

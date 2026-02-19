class_name UnitHyena
extends Unit

func _on_attack_hit(enemy: Enemy):
    super._on_attack_hit(enemy)
    var enemy_hp_percent = enemy.current_hp / enemy.max_hp

    if enemy_hp_percent < 0.25:
        var extra_hits = 1 if level < 3 else 2
        var damage_percent = 0.2 if level < 2 else 0.4
        for i in range(extra_hits):
            await get_tree().create_timer(0.1).timeout
            enemy.take_damage(damage * damage_percent, self)

    # Unit.gd emits `attack_performed` but doesn't call a method like `_on_attack_hit` unless I override `attack_performed` signal handler or hook into it.
    # Unit.gd `_do_melee_attack` emits `attack_performed(target)`.
    # I should connect `attack_performed` to `_on_attack_hit` in `_ready`.

func _ready():
    super._ready()
    attack_performed.connect(_on_attack_hit)

func _on_attack_hit(enemy):
    if enemy and is_instance_valid(enemy):
        var enemy_hp_percent = enemy.hp / max(1.0, enemy.max_hp)

        if enemy_hp_percent < 0.25:
            var extra_hits = 1 if level < 3 else 2
            var damage_percent = 0.2 if level < 2 else 0.4
            for i in range(extra_hits):
                await get_tree().create_timer(0.1 * (i+1)).timeout
                if is_instance_valid(enemy):
                    enemy.take_damage(damage * damage_percent, self, "physical", self)

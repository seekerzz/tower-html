class_name UnitFox
extends Unit

@export var charm_chance: float = 0.15
var charmed_enemies: Array[Enemy] = []
var max_charms: int = 1

func _ready():
    super._ready()
    if level >= 3:
        max_charms = 2

    # Need to connect when enemy attacks this unit.
    # Unit.gd has `take_damage(amount, source_enemy)`.
    # I should override `take_damage`?
    # Or hook into `take_damage`.
    # Unit.gd: `amount = behavior.on_damage_taken(amount, source_enemy)`
    # But Behavior handles it.
    # I can override `take_damage` in Unit.gd subclass.

func take_damage(amount: float, source_enemy = null):
    if source_enemy and is_instance_valid(source_enemy) and source_enemy is Enemy:
        _on_attacked_by_enemy(source_enemy)

    super.take_damage(amount, source_enemy)

func _on_attacked_by_enemy(enemy: Enemy):
    if charmed_enemies.size() < max_charms and randf() < charm_chance:
        if enemy.get("faction") != "player":
            _charm_enemy(enemy)

func _charm_enemy(enemy: Enemy):
    enemy.set_meta("charmed", true)
    enemy.set_meta("charm_source", self)
    charmed_enemies.append(enemy)
    # 敌人攻击其他敌人
    enemy.set("faction", "player")
    enemy.modulate = Color(1.0, 0.5, 1.0) # Pink charm
    GameManager.spawn_floating_text(enemy.global_position, "Charmed!", Color.MAGENTA)

    # Handle enemy AI switch immediately
    if enemy.behavior and enemy.behavior.has_method("cancel_attack"):
        enemy.behavior.cancel_attack()

    # Also handle cleanup if enemy dies
    enemy.died.connect(func(): charmed_enemies.erase(enemy))

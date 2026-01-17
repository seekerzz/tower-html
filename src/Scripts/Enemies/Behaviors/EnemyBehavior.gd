extends RefCounted

var enemy: CharacterBody2D
var data: Dictionary

func init(enemy_node: CharacterBody2D, data: Dictionary):
	enemy = enemy_node
	self.data = data

# Returns true if the behavior overrides the default movement/physics logic entirely.
# If false, the enemy might run some default fallback (though in our refactor, DefaultBehavior will handle it).
func physics_process(delta: float) -> bool:
	return false

func update_attack(delta: float):
	pass

func on_hit(damage_info: Dictionary):
	pass

func on_death():
	pass

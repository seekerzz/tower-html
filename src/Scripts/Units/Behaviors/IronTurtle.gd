extends DefaultBehavior
func on_damage_taken(amount: float, source: Node2D) -> float:
	var reduce = unit.unit_data.get("flat_amount", 0)
	return max(1, amount - reduce)

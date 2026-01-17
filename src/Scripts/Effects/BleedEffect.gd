extends StatusEffect

var stack_count: int = 1

func setup(target: Node, source: Node, params: Dictionary):
	super.setup(target, source, params)
	type_key = "bleed"
	# If initial setup passes stack_count, use it, otherwise default 1
	if params.has("stack_count"):
		stack_count = params.stack_count

func stack(params: Dictionary):
	# Refresh duration handled in super
	super.stack(params)

	# Increment stack count
	stack_count += 1

extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var area: Area2D = $Area2D

# Initial configuration function
func setup(texture: Texture2D, region_rect: Rect2, offset_pos: Vector2, flip_h: bool):
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region_rect
	sprite.flip_h = flip_h
	position += offset_pos

func _ready():
	# Connect to body_entered signal
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	# Check if the body belongs to the "enemies" group (group name found in Enemy.gd)
	if body.is_in_group("enemies"):
		shake_and_emit()

func shake_and_emit():
	if particles:
		particles.restart() # Use restart to ensure it plays even if it was playing
		particles.emitting = true

	# Simple shake tween
	var tween = create_tween()
	var original_pos = sprite.position

	# Shake sequence
	tween.tween_property(sprite, "position", original_pos + Vector2(2, 0), 0.05)
	tween.tween_property(sprite, "position", original_pos - Vector2(2, 0), 0.05)
	tween.tween_property(sprite, "position", original_pos + Vector2(1, 0), 0.05)
	tween.tween_property(sprite, "position", original_pos, 0.05)

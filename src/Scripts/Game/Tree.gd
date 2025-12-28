extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: GPUParticles2D = $GPUParticles2D

func setup(texture: Texture2D, region_rect: Rect2, offset: Vector2, flip_h: bool):
	if sprite:
		sprite.texture = texture
		sprite.region_enabled = true
		sprite.region_rect = region_rect
		sprite.flip_h = flip_h
		sprite.position = offset

func _ready():
	var area = $Area2D
	if area:
		# Connect to body_entered to detect PhysicsBody2D (like Enemy)
		if not area.body_entered.is_connected(_on_body_entered):
			area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body.is_in_group("enemies") or body.is_in_group("Enemy"):
		_trigger_effect()

func _trigger_effect():
	if particles:
		particles.restart()
		particles.emitting = true

	if sprite:
		var tween = create_tween()
		# Slight shake effect
		tween.tween_property(sprite, "rotation_degrees", 5.0, 0.1)
		tween.tween_property(sprite, "rotation_degrees", -5.0, 0.1)
		tween.tween_property(sprite, "rotation_degrees", 0.0, 0.1)

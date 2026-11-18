extends Node2D

const Visual = preload("res://scripts/actor_visual.gd")

var variant := "male"
var left_x := 0.0
var right_x := 0.0
var speed := 43.0
var direction := 1.0
var sprite: AnimatedSprite2D

func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.sprite_frames = Visual.villager_frames(variant)
	sprite.position.y = -56.0
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.flip_h = direction < 0.0
	add_child(sprite)
	sprite.play("walk")

func _process(delta: float) -> void:
	if GameState.dialogue_active or GameState.ending_started:
		sprite.pause()
		return
	if not sprite.is_playing():
		sprite.play("walk")
	position.x += direction * speed * delta
	if position.x >= right_x:
		position.x = right_x
		direction = -1.0
	elif position.x <= left_x:
		position.x = left_x
		direction = 1.0
	sprite.flip_h = direction < 0.0

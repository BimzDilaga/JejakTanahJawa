extends CharacterBody2D

signal defeated(enemy: Node)
const Visual = preload("res://scripts/actor_visual.gd")
var target: CharacterBody2D
var active: bool = true
var health: int = 3
var facing: int = -1
var dead: bool = false
var windup: float = 0.0
var cooldown: float = 0.7
var hurt_time: float = 0.0
var attack_flash: float = 0.0
var sprite: Sprite2D
var _clock: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 8.0
	var shape := CapsuleShape2D.new()
	shape.radius = 17.0
	shape.height = 98.0
	var collider := CollisionShape2D.new()
	collider.name = "CollisionShape2D"
	collider.shape = shape
	collider.position.y = -49.0
	add_child(collider)
	sprite = Visual.make_sprite("res://assets/Karakter/Tentara Belanda.png", 112.0)
	sprite.name = "Sprite2D"
	add_child(sprite)
	queue_redraw()

func _physics_process(delta: float) -> void:
	_clock += delta
	if not is_on_floor():
		velocity.y += 1450.0 * delta
	var locked: bool = dead or not active or not is_instance_valid(target) or GameState.dialogue_active or GameState.ending_started
	if is_instance_valid(target) and not target.get("controls_enabled"):
		locked = true
	if locked:
		velocity.x = 0.0
		windup = 0.0
		move_and_slide()
		queue_redraw()
		return
	cooldown = maxf(0.0, cooldown - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	attack_flash = maxf(0.0, attack_flash - delta)
	var offset: Vector2 = target.global_position - global_position
	facing = 1 if offset.x >= 0.0 else -1
	if hurt_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, delta * 650.0)
	elif windup > 0.0:
		velocity.x = 0.0
		windup -= delta
		if windup <= 0.0:
			attack_flash = 0.2
			cooldown = 1.4
			if absf(offset.x) < 85.0 and absf(offset.y) < 90.0:
				target.take_damage(1, global_position.x)
	elif absf(offset.x) < 78.0 and absf(offset.y) < 90.0:
		velocity.x = 0.0
		if cooldown <= 0.0:
			windup = 0.65
	elif absf(offset.x) < 500.0:
		velocity.x = float(facing) * 82.0
	else:
		velocity.x = 0.0
	move_and_slide()
	global_position.x = clampf(global_position.x, 40.0, 3720.0)
	sprite.flip_h = facing > 0
	sprite.position.y = -56.0 + (sin(_clock * 12.0) * 1.5 if absf(velocity.x) > 10.0 else 0.0)
	sprite.modulate = Color(1.0, 0.65, 0.5) if hurt_time > 0.0 else Color.WHITE
	sprite.rotation = -0.08 * facing if windup > 0.0 else 0.0
	queue_redraw()

func take_damage(amount: int, source_x: float) -> void:
	if dead or not active or GameState.dialogue_active or GameState.ending_started:
		return
	health = maxi(0, health - maxi(0, amount))
	hurt_time = 0.22
	windup = 0.0
	cooldown = maxf(cooldown, 0.65)
	velocity.x = 145.0 if global_position.x >= source_x else -145.0
	if health == 0:
		dead = true
		active = false
		collision_layer = 0
		remove_from_group("enemies")
		defeated.emit(self)
		queue_free()
	queue_redraw()

func _draw() -> void:
	if dead:
		return
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 27.0, Color(0.06, 0.08, 0.06, 0.3))
	draw_set_transform(Vector2.ZERO)
	for index in range(3):
		draw_rect(Rect2(-16.0 + index * 12.0, -128.0, 9.0, 4.0), Color("d8ae69") if index < health else Color("4a4b44"))
	if windup > 0.0:
		draw_circle(Vector2(0, -145), 10.0, Color("e7b75b"))
		draw_line(Vector2(0, -151), Vector2(0, -145), Color("352719"), 2.0)
		draw_circle(Vector2(0, -141), 1.5, Color("352719"))
	if attack_flash > 0.0:
		draw_line(Vector2(15.0 * facing, -60), Vector2(76.0 * facing, -60), Color(1.0, 0.68, 0.35, 0.8), 5.0)

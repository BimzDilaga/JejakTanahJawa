extends CharacterBody2D

signal defeated(enemy: Node)
const Visual = preload("res://scripts/actor_visual.gd")
const Shot = preload("res://scripts/patrol_shot.gd")
const MELEE_RANGE := 85.0
@export var world_right: float = 3720.0
@export var chase_speed: float = 82.0
@export var warning_time: float = 0.65
@export var recovery_time: float = 1.4
@export var shot_range: float = 475.0
var patrol_origin: float = 0.0
var patrol_radius: float = 130.0
var patrol_direction: float = 1.0
var target: CharacterBody2D
var active: bool = true
var health: int = 3
var facing: int = -1
var dead: bool = false
var windup: float = 0.0
var cooldown: float = 0.7
var hurt_time: float = 0.0
var stun_time: float = 0.0
var attack_flash: float = 0.0
var melee_attack := false
var sprite: AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemies")
	patrol_origin = position.x
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
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Visual.soldier_frames()
	sprite.position.y = -56.0
	add_child(sprite)
	_update_animation()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += 1450.0 * delta
	var locked: bool = dead or not active or not is_instance_valid(target) or GameState.dialogue_active or GameState.ending_started
	if is_instance_valid(target) and not target.get("controls_enabled"):
		locked = true
	if locked:
		velocity.x = 0.0
		windup = 0.0
		attack_flash = 0.0
		move_and_slide()
		_update_animation()
		queue_redraw()
		return
	cooldown = maxf(0.0, cooldown - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	stun_time = maxf(0.0, stun_time - delta)
	attack_flash = maxf(0.0, attack_flash - delta)
	var offset: Vector2 = target.global_position - global_position
	facing = 1 if offset.x >= 0.0 else -1
	if stun_time > 0.0 or hurt_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, delta * 650.0)
	elif windup > 0.0:
		velocity.x = 0.0
		windup -= delta
		if windup <= 0.0:
			attack_flash = 0.2
			cooldown = recovery_time
			if melee_attack:
				if absf(offset.x) < MELEE_RANGE and absf(offset.y) < 75.0:
					target.take_damage(1, global_position.x, true)
			else:
				var shot := Shot.new()
				shot.position = position + Vector2(30.0 * facing, -66.0)
				shot.direction = facing
				shot.distance_left = shot_range
				get_parent().add_child(shot)
	elif absf(offset.x) < shot_range and absf(offset.y) < 58.0:
		velocity.x = 0.0
		if cooldown <= 0.0:
			windup = warning_time
			melee_attack = absf(offset.x) < MELEE_RANGE
	elif absf(offset.x) < shot_range + 130.0:
		velocity.x = float(facing) * chase_speed
	else:
		if absf(position.x - patrol_origin) > patrol_radius:
			patrol_direction = -signf(position.x - patrol_origin)
		velocity.x = patrol_direction * chase_speed * 0.45
		facing = int(patrol_direction)
	move_and_slide()
	global_position.x = clampf(global_position.x, 40.0, world_right)
	_update_animation()
	queue_redraw()

func _update_animation() -> void:
	sprite.flip_h = facing < 0
	sprite.rotation = 0.0
	sprite.modulate = Color(1.0, 0.65, 0.5) if hurt_time > 0.0 else Color.WHITE
	if windup > 0.0 or attack_flash > 0.0:
		if melee_attack:
			sprite.pause()
			sprite.animation = "shoot"
			sprite.frame = 0
			sprite.rotation = -0.13 * facing if windup > 0.0 else 0.15 * facing
			return
		# Show the muzzle flash on the same tick as the attack.
		var frame_index := 4 + clampi(int((0.2 - attack_flash) * 30.0), 0, 5)
		if windup > 0.0:
			frame_index = clampi(int((1.0 - windup / warning_time) * 4.0), 0, 3)
		sprite.pause()
		sprite.animation = "shoot"
		sprite.frame = frame_index
	elif absf(velocity.x) > 10.0:
		if sprite.animation != &"walk" or not sprite.is_playing():
			sprite.play("walk")
	else:
		sprite.pause()
		sprite.animation = "shoot"
		sprite.frame = 0

func apply_stun(seconds: float) -> void:
	stun_time = maxf(stun_time, seconds)
	windup = 0.0
	attack_flash = 0.0

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
		set_physics_process(false)
		sprite.modulate = Color.WHITE
		sprite.play("defeat")
		sprite.animation_finished.connect(queue_free, CONNECT_ONE_SHOT)
		defeated.emit(self)
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
	if stun_time > 0.0:
		draw_arc(Vector2(0, -135), 14.0, 0.0, TAU, 12, Color("e7b75b"), 2.0)
	if attack_flash > 0.0 and melee_attack:
		draw_line(Vector2(18.0 * facing, -60), Vector2(76.0 * facing, -60), Color("e7b75b"), 3.0)

	if attack_flash > 0.0 and not melee_attack:
		var flash: Texture2D = preload("res://assets/Asset in game/gun efect.png")
		var frame_index := clampi(int((0.2 - attack_flash) * 20.0), 0, 3)
		draw_set_transform(Vector2(45 * facing, -66), 0.0, Vector2(facing, 1))
		draw_texture_rect_region(flash, Rect2(-21, -16, 42, 32), Rect2(frame_index * 543, 0, 543, 724))
		draw_set_transform(Vector2.ZERO)

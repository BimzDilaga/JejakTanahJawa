extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
const Visual = preload("res://scripts/actor_visual.gd")
const SPEED: float = 260.0
var max_health: int = 5
var health: int = 5
var facing: int = 1
var controls_enabled: bool = true
var current_interactable: Area2D = null
var is_attacking: bool = false
var attack_timer: float = 0.0
var attack_cooldown: float = 0.0
var invulnerable_time: float = 0.0
var hurt_time: float = 0.0
var dead: bool = false
var anim: AnimatedSprite2D
var _attack_hit: bool = false

func _ready() -> void:
	add_to_group("player")
	anim = AnimatedSprite2D.new()
	anim.name = "AnimatedSprite2D"
	anim.sprite_frames = Visual.jaka_frames()
	anim.position = Vector2(0, -56)
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(anim)
	anim.play("idle")
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += 1450.0 * delta
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var locked: bool = dead or not controls_enabled or GameState.dialogue_active or GameState.ending_started
	if locked:
		velocity.x = 0.0
		is_attacking = false
		attack_timer = 0.0
		move_and_slide()
		_update_animation(0.0)
		queue_redraw()
		return
	var direction: float = Input.get_axis("move_left", "move_right")
	if not is_attacking and direction != 0.0:
		facing = 1 if direction > 0.0 else -1
	if Input.is_action_just_pressed("attack"):
		perform_attack()
	if is_attacking:
		attack_timer -= delta
		if not _attack_hit and attack_timer <= 0.19:
			_attack_hit = true
			_hit_enemies()
		if attack_timer <= 0.0:
			is_attacking = false
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_attacking:
		velocity.y = -510.0
	if hurt_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 750.0 * delta)
	elif is_attacking:
		velocity.x = 0.0
	else:
		velocity.x = direction * SPEED
	move_and_slide()
	global_position.x = clampf(global_position.x, 40.0, 3720.0)
	_update_animation(direction)
	queue_redraw()

func perform_attack() -> void:
	if dead or not controls_enabled or GameState.dialogue_active or GameState.ending_started or attack_cooldown > 0.0:
		return
	is_attacking = true
	_attack_hit = false
	attack_timer = 0.34
	attack_cooldown = 0.53
	velocity.x = 0.0

func _hit_enemies() -> void:
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		var offset: Vector2 = (enemy as Node2D).global_position - global_position
		if offset.x * facing >= -8.0 and absf(offset.x) <= 145.0 and absf(offset.y) < 100.0:
			if enemy.has_method("take_damage"):
				enemy.take_damage(1, global_position.x)

func take_damage(amount: int, source_x: float) -> void:
	if dead or invulnerable_time > 0.0 or not controls_enabled or GameState.dialogue_active or GameState.ending_started:
		return
	health = maxi(0, health - maxi(0, amount))
	invulnerable_time = 1.05
	hurt_time = 0.22
	velocity.x = 170.0 if global_position.x >= source_x else -170.0
	health_changed.emit(health, max_health)
	if health == 0:
		dead = true
		is_attacking = false
		controls_enabled = false
		died.emit()
	queue_redraw()

func reset_health() -> void:
	health = max_health
	dead = false
	is_attacking = false
	_attack_hit = false
	attack_timer = 0.0
	attack_cooldown = 0.0
	invulnerable_time = 0.0
	hurt_time = 0.0
	velocity = Vector2.ZERO
	controls_enabled = true
	health_changed.emit(health, max_health)

func _update_animation(direction: float) -> void:
	anim.flip_h = facing < 0
	anim.modulate = Color(1.0, 0.64, 0.48) if hurt_time > 0.0 else Color.WHITE
	if invulnerable_time > 0.0:
		anim.modulate.a = 0.45 if int(invulnerable_time * 14.0) % 2 == 0 else 1.0
	anim.rotation = 0.0
	if is_attacking:
		anim.play("idle")
	elif not is_on_floor():
		anim.play("jump")
	elif absf(direction) > 0.0 and controls_enabled and not GameState.dialogue_active and not GameState.ending_started:
		anim.play("walk")
	else:
		anim.play("idle")

func _draw() -> void:
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 26.0, Color(0.06, 0.08, 0.06, 0.3))
	draw_set_transform(Vector2.ZERO)
	if is_attacking:
		# A clear, non-graphic rifle silhouette and brief shot line replace the hand-swing arc.
		var direction := float(facing)
		draw_line(Vector2(-10.0 * direction, -66), Vector2(43.0 * direction, -76), Color("5c3925"), 10.0, true)
		draw_line(Vector2(16.0 * direction, -71), Vector2(64.0 * direction, -80), Color("343b39"), 6.0, true)
		draw_line(Vector2(20.0 * direction, -67), Vector2(38.0 * direction, -57), Color("5c3925"), 5.0, true)
		if attack_timer <= 0.19 and attack_timer > 0.10:
			draw_line(Vector2(67.0 * direction, -80), Vector2(139.0 * direction, -80), Color(1.0, 0.86, 0.55, 0.9), 3.0, true)
			draw_circle(Vector2(67.0 * direction, -80), 7.0, Color(1.0, 0.8, 0.35, 0.9))

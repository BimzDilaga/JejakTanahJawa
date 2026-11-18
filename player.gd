extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
const Visual = preload("res://scripts/actor_visual.gd")
const SPEED: float = 260.0
const WALK_SPEED: float = 160.0
const PARRY_WINDOW := 0.4
const PARRY_COOLDOWN := 1.0
const HEAL_DURATION := 0.72
const ULTIMATE_HITS := 5
const ULTIMATE_DURATION := 0.5
const ULTIMATE_SPEED := 690.0
@export var world_right: float = 3720.0
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
var parry_time := 0.0
var parry_cooldown := 0.0
var _parry_flash := 0.0
var heal_time := 0.0
var ultimate_charge := 0
var ultimate_time := 0.0
var _ultimate_targets: Dictionary = {}

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
	parry_time = maxf(0.0, parry_time - delta)
	parry_cooldown = maxf(0.0, parry_cooldown - delta)
	_parry_flash = maxf(0.0, _parry_flash - delta)
	heal_time = maxf(0.0, heal_time - delta)
	var locked: bool = dead or not controls_enabled or GameState.dialogue_active or GameState.ending_started
	if locked:
		velocity.x = 0.0
		is_attacking = false
		attack_timer = 0.0
		parry_time = 0.0
		heal_time = 0.0
		ultimate_time = 0.0
		move_and_slide()
		_update_animation(0.0)
		queue_redraw()
		return
	var direction: float = Input.get_axis("move_left", "move_right")
	if not is_attacking and ultimate_time <= 0.0 and direction != 0.0:
		facing = 1 if direction > 0.0 else -1
	if Input.is_action_just_pressed("parry"):
		perform_parry()
	if Input.is_action_just_pressed("heal"):
		perform_heal()
	if Input.is_action_just_pressed("ultimate"):
		perform_ultimate()
	if Input.is_action_just_pressed("attack"):
		perform_attack()
	if is_attacking:
		attack_timer -= delta
		if not _attack_hit and attack_timer <= 0.19:
			_attack_hit = true
			_hit_enemies()
		if attack_timer <= 0.0:
			is_attacking = false
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_attacking and heal_time <= 0.0 and ultimate_time <= 0.0:
		velocity.y = -510.0
	var dashing := ultimate_time > 0.0
	if dashing:
		velocity.x = ULTIMATE_SPEED * facing
	elif hurt_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 750.0 * delta)
	elif is_attacking or heal_time > 0.0:
		velocity.x = 0.0
	else:
		velocity.x = direction * (SPEED if Input.is_action_pressed("sprint") else WALK_SPEED)
	var previous_position := global_position
	move_and_slide()
	global_position.x = clampf(global_position.x, 40.0, world_right)
	if dashing:
		_hit_dash_targets(previous_position)
		ultimate_time = maxf(0.0, ultimate_time - delta)
	_update_animation(direction)
	queue_redraw()

func perform_attack() -> void:
	if not _can_use_skill() or parry_time > 0.0 or attack_cooldown > 0.0:
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
			if enemy.has_method("take_damage") and enemy.get("active") and not enemy.get("dead"):
				enemy.take_damage(1, global_position.x)
				ultimate_charge = mini(ultimate_charge + 1, ULTIMATE_HITS)

func _can_use_skill() -> bool:
	return not dead and controls_enabled and not GameState.dialogue_active and not GameState.ending_started and heal_time <= 0.0 and ultimate_time <= 0.0

func perform_parry() -> bool:
	if not _can_use_skill() or parry_cooldown > 0.0:
		return false
	is_attacking = false
	parry_time = PARRY_WINDOW
	parry_cooldown = PARRY_COOLDOWN
	return true

func perform_heal() -> bool:
	if not _can_use_skill() or is_attacking or parry_time > 0.0 or health >= max_health:
		return false
	if GameState.heal_stock <= 0:
		return false
	GameState.heal_stock -= 1
	heal_time = HEAL_DURATION
	health += 1
	health_changed.emit(health, max_health)
	return true

func perform_ultimate() -> bool:
	if not _can_use_skill() or is_attacking or parry_time > 0.0 or ultimate_charge < ULTIMATE_HITS:
		return false
	ultimate_charge = 0
	ultimate_time = ULTIMATE_DURATION
	_ultimate_targets.clear()
	return true

func _hit_dash_targets(previous_position: Vector2) -> void:
	var left := minf(previous_position.x, global_position.x) - 25.0
	var right := maxf(previous_position.x, global_position.x) + 25.0
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		var id := enemy.get_instance_id()
		if _ultimate_targets.has(id) or not enemy.get("active") or enemy.get("dead"):
			continue
		if enemy.global_position.x < left or enemy.global_position.x > right or absf(enemy.global_position.y - global_position.y) >= 75.0:
			continue
		_ultimate_targets[id] = true
		enemy.take_damage(2, global_position.x)
		enemy.apply_stun(1.3)

func take_damage(amount: int, source_x: float, can_parry: bool = false) -> void:
	if dead or invulnerable_time > 0.0 or not controls_enabled or GameState.dialogue_active or GameState.ending_started:
		return
	if can_parry and amount > 0 and parry_time > 0.0:
		_parry_flash = 0.19
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
	parry_time = 0.0
	parry_cooldown = 0.0
	_parry_flash = 0.0
	heal_time = 0.0
	ultimate_time = 0.0
	ultimate_charge = 0
	_ultimate_targets.clear()
	velocity = Vector2.ZERO
	controls_enabled = true
	health_changed.emit(health, max_health)

func _update_animation(direction: float) -> void:
	anim.flip_h = facing < 0
	anim.modulate = Color(1.0, 0.64, 0.48) if hurt_time > 0.0 else Color.WHITE
	if invulnerable_time > 0.0:
		anim.modulate.a = 0.45 if int(invulnerable_time * 14.0) % 2 == 0 else 1.0
	anim.rotation = 0.0
	if ultimate_time > 0.0:
		anim.play("ultimate")
	elif parry_time > 0.0:
		anim.play("parry")
	elif heal_time > 0.0:
		anim.play("heal")
	elif is_attacking:
		anim.play("bamboo_attack")
	elif hurt_time > 0.0:
		anim.play("hurt")
	elif not is_on_floor():
		anim.play("jump")
	elif absf(direction) > 0.0 and controls_enabled and not GameState.dialogue_active and not GameState.ending_started:
		anim.play("run" if Input.is_action_pressed("sprint") else "walk")
	else:
		anim.play("idle")

func _draw() -> void:
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 26.0, Color(0.06, 0.08, 0.06, 0.3))
	draw_set_transform(Vector2.ZERO)
	if _parry_flash > 0.0:
		draw_arc(Vector2(0, -55), 51.0, -1.0, 4.1, 18, Color("ffe7a6"), 4.0, true)

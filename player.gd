extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
signal stance_changed(current: int, maximum: int)
signal parry_succeeded
signal stance_broken
const Visual = preload("res://scripts/jaka_visual.gd")
const Particles = preload("res://scripts/combat_particles.gd")
const SPEED: float = 260.0
const WALK_SPEED: float = 160.0
const PARRY_WINDOW := 0.4
const PARRY_COOLDOWN := 2.0
const PARRY_REACTION := 0.25
const STANCE_MAX := 5
const STANCE_RECOVERY_INTERVAL := 1.0
const STANCE_BREAK_DURATION := 2.0
const HEAL_DURATION := 0.72
const ULTIMATE_HITS := 5
const ULTIMATE_DURATION := 0.5
const ULTIMATE_SPEED := 690.0
const ATTACK_DURATIONS := [0.34,0.38,0.44]
const ATTACK_CONTACTS := [0.15,0.17,0.22]
const DASH_DURATION := 0.18
const DASH_SPEED := 640.0
const DASH_COOLDOWN := 1.0
@export var world_right: float = 3720.0
var max_health: int = 3
var health: int = 3
var stamina := 200.0
var max_stamina := 200.0
var stamina_warning := 0.0
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
var combo_step := 0
var _attack_queued := false
var dash_time := 0.0
var dash_cooldown := 0.0
var dash_backward := false
var _dash_direction := 1
var _death_elapsed := 0.0
var _landing_time := 0.0
var _dash_trail_time := 0.0
var parry_time := 0.0
var parry_cooldown := 0.0
var _parry_flash := 0.0
var heal_time := 0.0
var ultimate_charge := 0
var ultimate_time := 0.0
var _ultimate_targets: Dictionary = {}
var stance := 0
var stance_recovery_time := 0.0
var stun_time := 0.0
var parry_reaction := 0.0
var _white_flash := 0.0
var _step_time := 0.0
var _trail_time := 0.0
var effects: Node2D
var _wave: AnimatedSprite2D
var _flash_material: ShaderMaterial
var combat_audio: Node

func _ready() -> void:
	add_to_group("player")
	max_health = GameState.player_max_health()
	health = max_health
	max_stamina = GameState.player_max_stamina()
	stamina = max_stamina
	GameState.stats_changed.connect(refresh_stats)
	z_index = 2
	anim = AnimatedSprite2D.new()
	anim.name = "AnimatedSprite2D"
	anim.sprite_frames = Visual.frames()
	anim.position = Vector2(0, -72)
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var flash_shader := Shader.new()
	flash_shader.code = "shader_type canvas_item; uniform float white_flash = 0.0; void fragment(){ vec4 c = COLOR; c.rgb = mix(c.rgb, vec3(1.0), white_flash); COLOR = c; }"
	_flash_material = ShaderMaterial.new()
	_flash_material.shader = flash_shader
	anim.material = _flash_material
	add_child(anim)
	anim.play("idle")
	_wave = AnimatedSprite2D.new()
	_wave.sprite_frames = anim.sprite_frames
	_wave.position = Vector2(38, -72)
	_wave.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_wave.hide()
	add_child(_wave)
	effects = Particles.new()
	effects.name = "CombatParticles"
	add_child(effects)
	combat_audio = preload("res://scripts/combat_audio.gd").new()
	add_child(combat_audio)
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if dead: _death_elapsed += delta
	_landing_time = maxf(0,_landing_time-delta)
	if not is_on_floor():
		velocity.y += 1450.0 * delta
	var locked: bool = dead or not controls_enabled or GameState.dialogue_active or GameState.ending_started
	if locked:
		velocity.x = 0.0
		_cancel_attack()
		dash_time = 0.0
		parry_time = 0.0
		parry_reaction = 0.0
		heal_time = 0.0
		ultimate_time = 0.0
		move_and_slide()
		_update_animation(0.0)
		queue_redraw()
		return
	_tick_combat(delta)
	var direction: float = Input.get_axis("move_left", "move_right")
	if not is_attacking and dash_time<=0 and ultimate_time <= 0.0 and parry_time <= 0.0 and stun_time <= 0.0 and direction != 0.0:
		facing = 1 if direction > 0.0 else -1
	if Input.is_action_just_pressed("heal"):
		perform_heal()
	if Input.is_action_just_pressed("ultimate"):
		perform_ultimate()
	if Input.is_action_just_pressed("dash"):
		perform_dash(Input.is_action_pressed("backstep"))
	if is_attacking:
		attack_timer -= delta
		if not _attack_hit and attack_timer <= float(ATTACK_DURATIONS[combo_step-1])-float(ATTACK_CONTACTS[combo_step-1]):
			_attack_hit = true
			_hit_enemies()
		if attack_timer <= 0.0:
			if _attack_queued and combo_step<3:
				_start_attack(combo_step+1)
			else:
				_cancel_attack()
	if Input.is_action_just_pressed("jump") and is_on_floor() and _can_use_skill(true) and not is_attacking and parry_time <= 0.0 and _spend_stamina(float(GameState.progression.jump_stamina)):
		velocity.y = -510.0
		effects.dust(global_position,0.55)
	var dashing := ultimate_time > 0.0
	if stun_time > 0.0:
		velocity.x = 0.0
	elif dash_time>0:
		velocity.x = DASH_SPEED*_dash_direction
	elif dashing:
		velocity.x = ULTIMATE_SPEED * facing
	elif hurt_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 750.0 * delta)
	elif is_attacking or heal_time > 0.0 or parry_time > 0.0:
		velocity.x = 0.0
	else:
		var speed := SPEED+int(GameState.upgrade_levels.speed)*float(GameState.progression.run_speed_per_level) if Input.is_action_pressed("sprint") else WALK_SPEED+int(GameState.upgrade_levels.speed)*float(GameState.progression.walk_speed_per_level)
		velocity.x = direction*speed
	var previous_position := global_position
	var was_grounded := is_on_floor()
	var falling_speed := velocity.y
	move_and_slide()
	global_position.x = clampf(global_position.x, 40.0, world_right)
	if not was_grounded and is_on_floor() and falling_speed > 80.0:
		_landing_time = 0.12
		effects.dust(global_position,clampf(falling_speed/350.0,0.6,1.8))
	if dash_time>0:
		dash_time = maxf(0,dash_time-delta)
		_dash_trail_time -= delta
		if _dash_trail_time<=0:
			_dash_trail_time = 0.035
			effects.burst(global_position+Vector2(0,-25),4,Color("d6c4a1"),0.45,Vector2(-_dash_direction,-0.2))
	_step_time -= delta
	if is_on_floor() and absf(velocity.x) > 20.0 and _step_time <= 0.0:
		_step_time = 0.17 if Input.is_action_pressed("sprint") else 0.32
		effects.dust(global_position-Vector2(facing*8,0),0.32 if Input.is_action_pressed("sprint") else 0.22,-facing)
	if dashing:
		_hit_dash_targets(previous_position)
		ultimate_time = maxf(0.0, ultimate_time - delta)
		_trail_time -= delta
		if _trail_time <= 0.0:
			_trail_time = 0.04
			effects.burst(global_position + Vector2(0, -40), 5, Color("edc366"), 0.6, Vector2(-facing, -0.4))
	_update_animation(direction)
	if is_on_floor() and not is_attacking and parry_time<=0 and parry_reaction<=0 and heal_time<=0 and ultimate_time<=0 and dash_time<=0 and hurt_time<=0 and stun_time<=0:
		stamina = minf(max_stamina,stamina+float(GameState.progression.stamina_recovery_per_second)*delta)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	# UI buttons consume mouse clicks before combat receives them.
	if event.is_echo(): return
	if event.is_action_pressed("parry"):
		perform_parry()
	elif event.is_action_pressed("attack"):
		perform_attack()

func _tick_combat(delta: float) -> void:
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	dash_cooldown = maxf(0,dash_cooldown-delta)
	stamina_warning = maxf(0,stamina_warning-delta)
	parry_cooldown = maxf(0.0, parry_cooldown - delta)
	parry_reaction = maxf(0.0, parry_reaction - delta)
	_parry_flash = maxf(0.0, _parry_flash - delta)
	_white_flash = maxf(0.0, _white_flash - delta)
	heal_time = maxf(0.0, heal_time - delta)
	stun_time = maxf(0.0, stun_time - delta)
	if parry_time > 0.0:
		parry_time = maxf(0.0, parry_time - delta)
		stance_recovery_time = 0.0
		if parry_time <= 0.0:
			parry_cooldown = PARRY_COOLDOWN
	elif stance > 0:
		# Recover one point per second without parrying, including during stun.
		stance_recovery_time += delta
		while stance_recovery_time + 0.00001 >= STANCE_RECOVERY_INTERVAL and stance > 0:
			stance_recovery_time = maxf(0.0, stance_recovery_time - STANCE_RECOVERY_INTERVAL)
			stance -= 1
			stance_changed.emit(stance, STANCE_MAX)
	else:
		stance_recovery_time = 0.0

func perform_attack() -> void:
	if not _can_use_skill() or parry_time > 0.0:
		return
	if is_attacking:
		# One fresh click buffers one follow-up; holding never repeats the chain.
		if combo_step<3 and float(ATTACK_DURATIONS[combo_step-1])-attack_timer>=0.10:
			_attack_queued = true
		return
	if attack_cooldown>0: return
	_start_attack(1)

func _start_attack(step: int) -> void:
	if not _spend_stamina(float(GameState.progression.attack_stamina)):
		_cancel_attack()
		return
	combo_step = step
	_attack_queued = false
	is_attacking = true
	_attack_hit = false
	attack_timer = float(ATTACK_DURATIONS[step-1])
	attack_cooldown = attack_timer+0.19
	velocity.x = 0.0
	combat_audio.play_effect("swing_%d" % step)

func _cancel_attack() -> void:
	is_attacking = false
	attack_timer = 0.0
	combo_step = 0
	_attack_queued = false

func perform_dash(backward := false) -> bool:
	if not _can_use_skill() or parry_time>0 or dash_cooldown>0: return false
	_cancel_attack()
	dash_backward = backward
	_dash_direction = facing*(-1 if backward else 1)
	dash_time = DASH_DURATION
	dash_cooldown = DASH_COOLDOWN
	_dash_trail_time = 0
	_landing_time = 0
	velocity.x = DASH_SPEED*_dash_direction
	effects.dust(global_position,0.65,-_dash_direction)
	return true

func _hit_enemies() -> void:
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		var offset: Vector2 = (enemy as Node2D).global_position - global_position
		if offset.x * facing >= -8.0 and absf(offset.x) <= 145.0 and absf(offset.y) < 100.0:
			if enemy.has_method("take_damage") and enemy.get("active") and not enemy.get("dead"):
				var accepted: Variant = enemy.call("take_damage",GameState.player_attack(),global_position.x)
				if accepted is bool and not accepted:
					continue
				ultimate_charge = mini(ultimate_charge + 1, ULTIMATE_HITS)
				effects.burst((enemy as Node2D).global_position + Vector2(0, -55), 12, Color("ffc985"), 1.0, Vector2(facing, -0.4))
				effects.impact((enemy as Node2D).global_position+Vector2(0,-55),Color("ffe1a2"),0.65)

func _can_use_skill(allow_dash := false) -> bool:
	return not dead and controls_enabled and not GameState.dialogue_active and not GameState.ending_started and stun_time <= 0.0 and heal_time <= 0.0 and ultimate_time <= 0.0 and (allow_dash or dash_time<=0)

func perform_parry() -> bool:
	if not _can_use_skill() or parry_cooldown > 0.0 or parry_time > 0.0:
		return false
	_cancel_attack()
	parry_reaction = 0.0
	stance_recovery_time = 0.0
	if stance >= STANCE_MAX:
		_break_stance()
		return false
	if not _spend_stamina(float(GameState.progression.parry_stamina)): return false
	parry_time = PARRY_WINDOW
	_white_flash = 0.13
	_update_animation(0.0)
	return true

func add_stance_load(points: int) -> void:
	if points<=0 or dead:
		return
	var overflow := stance+points>STANCE_MAX
	stance = mini(STANCE_MAX,stance+points)
	stance_recovery_time = 0.0
	stance_changed.emit(stance,STANCE_MAX)
	if overflow:
		_break_stance()

func _break_stance() -> void:
	_cancel_attack()
	dash_time = 0.0
	if parry_time>0: parry_cooldown = PARRY_COOLDOWN
	parry_time = 0.0
	stun_time = STANCE_BREAK_DURATION
	velocity.x = 0.0
	stance_broken.emit()
	effects.burst(global_position + Vector2(0,-50),18,Color("c9906d"),1.2)

func _complete_parry(parry_audio: AudioStream = null) -> void:
	parry_time = 0.0
	parry_cooldown = 0.0
	parry_reaction = PARRY_REACTION
	stance = mini(STANCE_MAX, stance + 1)
	stance_recovery_time = 0.0
	_parry_flash = 0.19
	_white_flash = 0.13
	stance_changed.emit(stance, STANCE_MAX)
	parry_succeeded.emit()
	combat_audio.play_effect("parry",parry_audio)
	effects.burst(global_position + Vector2(35 * facing, -65), 22, Color("ffe7a6"), 1.5, Vector2(facing, -0.4))
	effects.impact(global_position+Vector2(35*facing,-65),Color("fff3cf"),1.25,true)
	_update_animation(0.0)

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
	_wave.play("ultimate_wave")
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
		var accepted: Variant = enemy.call("take_damage",GameState.player_attack()*2,global_position.x)
		if accepted is bool and not accepted:
			continue
		enemy.apply_stun(1.3)

func take_damage(amount: int, source_x: float, can_parry: bool = false, knockback := 170.0, parry_audio: AudioStream = null) -> bool:
	if dead or amount <= 0 or invulnerable_time > 0.0 or not controls_enabled or GameState.dialogue_active or GameState.ending_started:
		return false
	if can_parry and amount > 0 and parry_time > 0.0:
		_complete_parry(parry_audio)
		return true
	if parry_time>0.0:
		parry_cooldown = PARRY_COOLDOWN
	_cancel_attack()
	dash_time = 0.0
	parry_time = 0.0
	parry_reaction = 0.0
	heal_time = 0.0
	ultimate_time = 0.0
	health = maxi(0, health - maxi(0, amount))
	invulnerable_time = 1.05
	hurt_time = 0.22
	velocity.x = knockback if global_position.x >= source_x else -knockback
	effects.burst(global_position + Vector2(0, -55), 12, Color("e6b891"), 0.9, Vector2(signf(global_position.x - source_x), -0.4))
	health_changed.emit(health, max_health)
	if health == 0:
		dead = true
		_death_elapsed = 0.0
		is_attacking = false
		controls_enabled = false
		died.emit()
	queue_redraw()
	return false

func reset_health() -> void:
	refresh_stats()
	health = max_health
	stamina = max_stamina
	stamina_warning = 0
	dead = false
	_cancel_attack()
	dash_time = 0.0
	dash_cooldown = 0.0
	_death_elapsed = 0.0
	_landing_time = 0.0
	combat_audio.stop_all()
	_attack_hit = false
	attack_timer = 0.0
	attack_cooldown = 0.0
	invulnerable_time = 0.0
	hurt_time = 0.0
	parry_time = 0.0
	parry_cooldown = 0.0
	_parry_flash = 0.0
	_white_flash = 0.0
	parry_reaction = 0.0
	stance = 0
	stance_recovery_time = 0.0
	stun_time = 0.0
	heal_time = 0.0
	ultimate_time = 0.0
	ultimate_charge = 0
	_ultimate_targets.clear()
	velocity = Vector2.ZERO
	controls_enabled = true
	if is_instance_valid(effects):
		effects.clear()
	health_changed.emit(health, max_health)
	stance_changed.emit(stance, STANCE_MAX)

func refresh_stats() -> void:
	var previous := max_health
	max_health = GameState.player_max_health()
	health = clampi(health+maxi(0,max_health-previous),0,max_health)
	max_stamina = GameState.player_max_stamina()
	stamina = minf(stamina,max_stamina)
	health_changed.emit(health,max_health)

func _spend_stamina(amount: float) -> bool:
	if stamina+0.0001<amount:
		stamina_warning = 0.3
		return false
	stamina = maxf(0,stamina-amount)
	return true

func parry_status() -> String:
	if stun_time > 0.0:
		return "STUN %.1f dtk" % stun_time
	if parry_cooldown > 0.0:
		return "%.1f dtk" % parry_cooldown
	if stance >= STANCE_MAX:
		return "BATAS — tunggu pulih"
	return "siap" if parry_time <= 0.0 else "tangkis"

func _update_animation(direction: float) -> void:
	anim.flip_h = facing < 0
	anim.modulate = Color(1.0, 0.64, 0.48) if hurt_time > 0.0 else Color.WHITE
	if invulnerable_time > 0.0:
		anim.modulate.a = 0.45 if int(invulnerable_time * 14.0) % 2 == 0 else 1.0
	anim.rotation = 0.0
	_flash_material.set_shader_parameter("white_flash", clampf(_white_flash / 0.13, 0.0, 1.0))
	_wave.visible = ultimate_time > 0.0
	_wave.flip_h = facing < 0
	_wave.position.x = 38 * facing
	if dead:
		_manual_pose("death",_death_elapsed/0.8)
	elif stun_time > 0.0:
		var elapsed := STANCE_BREAK_DURATION-stun_time
		_manual_pose("stun",elapsed/0.3 if elapsed<0.3 else (stun_time/0.3 if stun_time<0.3 else 1.0))
	elif dash_time>0:
		_manual_pose("backdash" if dash_backward else "dash",1-dash_time/DASH_DURATION)
	elif ultimate_time > 0.0:
		anim.play("ultimate")
	elif parry_time > 0.0:
		anim.animation = "parry"
		anim.pause()
		anim.frame = 0
	elif heal_time > 0.0:
		anim.play("heal")
	elif is_attacking:
		_manual_pose("keris_attack" if combo_step==1 else "chain_%d" % combo_step,1-attack_timer/float(ATTACK_DURATIONS[combo_step-1]))
	elif hurt_time > 0.0:
		anim.play("hurt")
	elif parry_reaction > 0.0:
		anim.animation = "parry"
		anim.pause()
		anim.frame = clampi(1 + int((PARRY_REACTION - parry_reaction) * 20.0), 1, 5)
	elif not is_on_floor():
		anim.animation = "jump"
		anim.pause()
		anim.frame = 0 if velocity.y < -480 else (1 if velocity.y < -220 else (2 if velocity.y<0 else (3 if velocity.y<200 else 4)))
	elif _landing_time>0:
		_manual_pose("jump",1)
	elif absf(direction) > 0.0 and controls_enabled and not GameState.dialogue_active and not GameState.ending_started:
		anim.play("run" if Input.is_action_pressed("sprint") else "walk")
	else:
		anim.play("idle")

func _manual_pose(animation: String, progress: float) -> void:
	anim.animation = animation
	anim.pause()
	anim.frame = clampi(int(progress*6),0,5)

func _draw() -> void:
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 26.0, Color(0.06, 0.08, 0.06, 0.3))
	draw_set_transform(Vector2.ZERO)
	if _parry_flash > 0.0:
		draw_arc(Vector2(0, -55), 51.0, -1.0, 4.1, 18, Color("ffe7a6"), 4.0, true)
	if is_attacking and attack_timer < 0.23 and attack_timer > 0.06:
		draw_set_transform(Vector2(18 * facing, -55), 0, Vector2(facing, 1))
		draw_arc(Vector2.ZERO, 43, -1.1, 1.2, 10, Color("fff0b4"), 3.0, false)
		draw_set_transform(Vector2.ZERO)
	if stun_time > 0.0:
		draw_arc(Vector2(0, -119), 12, 0, TAU, 12, Color("e8c581"), 2.0)

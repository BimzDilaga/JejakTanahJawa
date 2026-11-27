extends CharacterBody2D
signal defeated(boss: Node)
signal phase_transition_started
signal phase_changed(phase: int)
const Visual = preload("res://scripts/boss_visual.gd")
var kind := "buto"
var arena: Node2D
var target: CharacterBody2D
var tuning: Dictionary
var sprite: AnimatedSprite2D
var active := true
var dead := false
var invulnerable := true
var health := 1
var max_health := 1
var stance := 0
var stance_max := 1
var facing := -1
var state := "spawn"
var state_time := 0.0
var stun_time := 0.0
var hurt_time := 0.0
var current_combo := 0
var combo_index := 0
var ground_round := 0
var sequence := 0
var attack: Dictionary = {}
var combo: Array[Dictionary] = []
var strike_done := false
var _air_timer := 0.0
var _air_index := 0
var _air_elapsed := 0.0
var _landing_from := Vector2.ZERO
var _landing_target := Vector2.ZERO
var air_cooldown := 0.0
var _ember_timer := 0.0
var _step_timer := 0.0
var phase := 1
var _footstep_index := 0
var _air_cast_locked := false
var _air_aim := Vector2.ZERO
var _air_effect := "projectile"

func tempo() -> float:
	return float(tuning.get("phase_two_tempo",1.25)) if phase>=2 else 1.0

func in_phase_transition() -> bool:
	return state in ["phase_fall","phase_hold","phase_rise"]

func _ready() -> void:
	tuning = JSON.parse_string(FileAccess.get_file_as_string("res://data/boss_tuning.json"))[kind]
	max_health = int(tuning.health)
	health = max_health
	air_cooldown = float(tuning.get("flight_cooldown",16.0))
	stance_max = int(tuning.stance_max)
	add_to_group("enemies")
	add_to_group("bosses")
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 8
	z_index = 2
	var collider := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 32 if kind=="buto" else (18 if kind=="headless" else 25)
	shape.height = 180 if kind=="buto" else (112 if kind=="headless" else (155 if kind=="commander" else 130))
	collider.shape = shape
	collider.position.y = -shape.height/2
	add_child(collider)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Visual.frames(kind)
	var visual_scale: float = float(tuning.get("visual_scale",1.0))
	sprite.scale = Vector2.ONE*visual_scale
	sprite.position.y = -144*visual_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	_pose("spawn",0)
	if kind in ["buto","commander"]: target.effects.dust(position,1.6)
	elif kind=="banaspati": target.effects.embers(position+Vector2(0,-65),16)
	else: target.effects.burst(position+Vector2(0,-90),16,Color("aa76bd"),0.7)

func _physics_process(delta: float) -> void:
	if (GameState.dialogue_active or GameState.ending_started) and not dead:
		return
	state_time += delta
	hurt_time = maxf(0,hurt_time-delta)
	sprite.modulate = Color(1,0.72,0.56) if hurt_time>0 else Color.WHITE
	sprite.flip_h = facing<0
	if state=="dead":
		_pose("death",state_time/0.9)
		sprite.modulate.a = clampf(1-(state_time-0.9)/0.6,0,1)
		return
	if in_phase_transition():
		match state:
			"phase_fall":
				_pose("death",state_time/0.9)
				if state_time>=0.9: _set_state("phase_hold")
			"phase_hold":
				_pose("death",1)
				if state_time>=float(tuning.get("phase_hold",2.0)): _set_state("phase_rise")
			"phase_rise":
				_pose("death",1-state_time/0.9)
				if state_time>=0.9:
					phase += 1
					health = max_health
					stance = 0
					active = true
					invulnerable = false
					air_cooldown = float(tuning.get("flight_cooldown",16))/tempo()
					_set_state("recovery")
					phase_changed.emit(phase)
		return
	if kind=="banaspati" and is_instance_valid(target):
		_ember_timer -= delta
		if _ember_timer<=0:
			_ember_timer = 0.09
			target.effects.embers(position+Vector2(0,-115),2)
	if state=="spawn":
		_pose("spawn",state_time/1.0)
		if state_time>=1.0:
			invulnerable = false
			_set_state("idle")
		return
	if not is_instance_valid(target) or not target.controls_enabled or target.dead:
		return
	if state=="flight":
		_tick_flight(delta)
		return
	if state=="descend":
		velocity = Vector2.ZERO
		var progress := minf(state_time/0.6,1.0)
		position = _landing_from.lerp(_landing_target,smoothstep(0,1,progress))
		_pose("descend",progress)
		if progress>=1 and target.position.x>arena.chase_end+70 and target.is_on_floor():
			arena.finish_chase()
			invulnerable = false
			air_cooldown = float(tuning.flight_cooldown)/tempo()
			_set_state("recovery")
		return
	if kind=="banaspati":
		air_cooldown = maxf(0,air_cooldown-delta)
		if air_cooldown<=0 and state in ["idle","recovery"] and arena.begin_chase():
			_start_flight()
			return
	if not is_on_floor(): velocity.y += 1450*delta
	velocity.x = 0
	match state:
		"stagger_in":
			_pose("stagger",state_time/0.4)
			if state_time>=0.4: _set_state("stagger_hold")
		"stagger_hold":
			_pose("stagger",1)
			if state_time>=float(tuning.stance_hold): _set_state("stagger_out")
		"stagger_out":
			_pose("stagger",1-state_time/0.4)
			if state_time>=0.4:
				stance = 0
				_set_state("idle")
		"stun":
			_pose("stagger",0.5)
			if state_time>=stun_time: _set_state("idle")
		"windup":
			_pose(attack.animation,minf(0.32,state_time/_windup()*0.32))
			if state_time>=_windup():
				strike_done = false
				_set_state("attack")
		"attack":
			var duration := float(attack.get("duration",0.45 if attack.get("lunge",false) else 0.30))/tempo()
			_pose(attack.animation,0.32+0.68*minf(1,state_time/duration))
			if attack.get("lunge",false): velocity.x = facing*float(attack.get("lunge_speed",600.0))
			var delay := float(attack.get("contact",0.28 if attack.get("lunge",false) else 0.08))/tempo()
			if not strike_done and state_time>=delay:
				strike_done = true
				_strike()
			if state=="attack" and state_time>=duration:
				combo_index += 1
				if combo_index<combo.size(): _begin_strike()
				else: _set_state("recovery")
		"recovery":
			_pose("idle",0)
			if state_time>=float(tuning.recovery)/tempo():
				_set_state("idle")
		_:
			var distance := target.position.x-position.x
			facing = 1 if distance>=0 else -1
			if absf(distance)>float(tuning.melee_range)+45:
				velocity.x = facing*float(tuning.run_speed if absf(distance)>430 else tuning.walk_speed)*(1.12 if phase>=2 else 1.0)
				sprite.play("run" if absf(distance)>430 and sprite.sprite_frames.has_animation("run") else "walk")
				sprite.speed_scale = 1.5 if absf(distance)>430 else 1.0
				if kind=="buto" and absf(distance)<430 and state_time>0.45:
					start_combo(2)
			elif state_time>0.55/tempo():
				_choose_attack()
			else: _pose("idle",0)
	move_and_slide()
	if hurt_time>0 and state in ["idle","recovery","reload"] and sprite.sprite_frames.has_animation("hurt"):
		_pose("hurt",1.0-hurt_time/0.16)
	_step_timer -= delta
	if is_on_floor() and absf(velocity.x)>30 and _step_timer<=0:
		_step_timer = 0.18
		target.effects.dust(position,0.65 if kind=="buto" else 0.4,-facing)
		if kind=="buto":
			arena.play_buto_sound("footstep_a" if _footstep_index%2==0 else "footstep_b",position)
			_footstep_index += 1
		elif kind=="headless":
			arena.play_headless_sound("step_a" if _footstep_index%2==0 else "step_b",position)
			_footstep_index += 1
	position.x = clampf(position.x,70,arena.ground_boss_limit())
	queue_redraw()

func _set_state(value: String) -> void:
	state = value
	state_time = 0
	if value=="flight": _air_elapsed = 0
	queue_redraw()

func _windup() -> float:
	return float(tuning.heavy_windup if attack.get("heavy",false) else tuning.windup)/tempo()

func _choose_attack() -> void:
	if kind=="banaspati":
		start_combo(1 if ground_round%2==0 else 3)
		ground_round += 1
	else:
		var pick := sequence%4
		sequence += 1
		if pick==1: start_combo(1)
		elif pick==3: start_combo(3)
		else:
			current_combo = 0
			combo = [{"animation":"light" if pick==0 else "heavy","heavy":pick==2,"effect":"melee"}]
			combo_index = 0
			_begin_strike()

func start_combo(number: int) -> void:
	current_combo = number
	combo.clear()
	for index in range(4 if number==2 else 5):
		var heavy := index==4 or (number==2 and index==3) or (number==3 and index==2)
		var effect := "melee"
		if kind=="banaspati":
			effect = (["melee","melee","projectile","wave","melee"] if number==1 else ["mark","wave","pillar","spread","dive"])[index]
			heavy = effect in ["wave","pillar","dive","mark"] or index==4
		combo.append({"animation":"combo_%d_%d" % [number,index+1],"heavy":heavy,"effect":effect,"lunge":kind in ["buto","headless"] and number==2 and index==0})
	combo_index = 0
	_begin_strike()

func _begin_strike() -> void:
	attack = combo[combo_index]
	attack["aim_point"] = target.position
	facing = 1 if target.position.x>=position.x else -1
	_set_state("windup")
	if kind=="buto" and attack.get("heavy",false): arena.play_buto_sound("heavy_windup",position)

func _strike() -> void:
	if attack.effect!="melee":
		arena.emit_boss_attack(self,attack.effect)
		return
	if kind=="buto": arena.play_buto_sound("heavy_impact" if attack.heavy else ("light_swing" if combo_index%2==0 else "reverse_swing"),position)
	var offset := target.position-position
	if offset.x*facing>=-25 and absf(offset.x)<=float(attack.get("range",tuning.melee_range)) and absf(offset.y)<float(attack.get("hit_height",140)):
		if kind=="buto" and attack.heavy and target.parry_time>0 and target.invulnerable_time<=0:
			target.add_stance_load(2)
		var push := float(tuning.get("heavy_knockback",380) if attack.heavy else tuning.get("light_knockback",250))
		var parried: bool = target.take_damage(int(tuning.heavy_damage if attack.heavy else tuning.damage),position.x,not attack.heavy,push)
		if parried: on_parried()
	if kind=="buto" and current_combo==3 and combo_index==4:
		arena.emit_boss_attack(self,"earth_wave")
	if is_instance_valid(target.effects):
		target.effects.burst(position+Vector2(facing*110,-35),12,Color("d6b278"),1.1)
		if kind=="buto" and attack.heavy:
			target.effects.dust(position+Vector2(facing*90,0),1.7)
		elif kind=="banaspati":
			target.effects.embers(position+Vector2(facing*70,-50),10,Vector2(facing,-0.4))

func _tick_flight(delta: float) -> void:
	_air_elapsed += delta
	velocity = Vector2.ZERO
	var desired := Vector2(minf(target.position.x+360,arena.chase_end+420),400)
	position = position.lerp(desired,1-exp(-delta*3.2))
	facing = -1
	sprite.flip_h = true
	_air_timer -= delta
	if not _air_cast_locked and _air_timer<=float(tuning.get("air_cast_windup",0.38))/tempo():
		_air_cast_locked = true
		_air_aim = target.position
		_air_effect = ["projectile","projectile","pillar","projectile","spread","projectile"][_air_index%6]
	if _air_timer<=0:
		_air_index += 1
		_air_timer = float(tuning.air_shot_interval)/tempo()
		arena.emit_boss_attack(self,_air_effect,_air_aim)
		_air_cast_locked = false
		state_time = 0
	if _air_elapsed<0.6:
		_pose("rise",_air_elapsed/0.6)
	elif _air_cast_locked:
		_pose("air_%d" % [(_air_index%8)+1],0.3)
	elif state_time<0.5:
		_pose("air_%d" % [(_air_index%8)+1],minf(1,state_time/0.5))
	else:
		sprite.speed_scale = 1.0
		sprite.play("hover")
	if target.position.x>arena.chase_end-100:
		arena.announce_landing()
		_landing_from = position
		_landing_target = Vector2(arena.chase_end+400,570)
		_set_state("descend")
		current_combo = 3
	queue_redraw()

func _start_flight() -> void:
	invulnerable = true
	current_combo = 2
	_set_state("flight")
	_air_timer = 0.65
	_air_cast_locked = false
	arena.play_banaspati_sound("rise",position)
	arena.play_banaspati_sound("laugh",position)

func on_parried() -> void:
	if dead or invulnerable or state.begins_with("stagger"):
		return
	stance = mini(stance_max,stance+int(tuning.parry_stance))
	hurt_time = 0.12
	if stance>=stance_max: _break_stance()

func take_damage(amount: int, _source_x: float) -> bool:
	if dead or amount<=0 or not active or invulnerable or GameState.ending_started or GameState.dialogue_active:
		return false
	health = maxi(0,health-amount)
	hurt_time = 0.16
	if health==0:
		if phase<int(tuning.get("phase_count",2)):
			active = false
			invulnerable = true
			velocity = Vector2.ZERO
			_set_state("phase_fall")
			if kind=="buto": arena.play_buto_sound("death",position)
			elif kind=="headless": arena.play_headless_sound("death",position)
			phase_transition_started.emit()
			return true
		dead = true
		active = false
		remove_from_group("enemies")
		_set_state("dead")
		if kind=="buto": arena.play_buto_sound("death",position)
		elif kind=="headless": arena.play_headless_sound("death",position)
		defeated.emit(self)
	elif not state.begins_with("stagger"):
		if kind=="buto": arena.play_buto_sound("pain",position)
		elif kind=="headless": arena.play_headless_sound("pain",position)
		stance = mini(stance_max,stance+int(tuning.hit_stance))
		if stance>=stance_max: _break_stance()
	return true

func _break_stance() -> void:
	velocity.x = 0
	target.effects.dust(position,1.0)
	target.effects.impact(position+Vector2(0,-75),Color("ffdc9f"),1.1)
	_set_state("stagger_in")
	var themed: bool = arena.play_buto_sound("break",position) if kind=="buto" else (arena.play_headless_sound("break",position) if kind=="headless" else false)
	if not themed: target.combat_audio.play_effect("boss-stance-break")
	if kind=="banaspati": arena.play_banaspati_sound("break",position)

func apply_stun(seconds: float) -> void:
	if dead or invulnerable or state.begins_with("stagger"):
		return
	stun_time = seconds
	_set_state("stun")

func _pose(animation: String, progress: float) -> void:
	sprite.speed_scale = 1.0
	sprite.animation = animation
	sprite.pause()
	sprite.frame = clampi(int(progress*(sprite.sprite_frames.get_frame_count(animation)-1)),0,sprite.sprite_frames.get_frame_count(animation)-1)

func _draw() -> void:
	if state not in ["flight","descend"]:
		draw_set_transform(Vector2(0,-2),0,Vector2(1,0.18))
		draw_circle(Vector2.ZERO,55,Color(0.04,0.04,0.05,0.25))
		draw_set_transform(Vector2.ZERO)
	if state=="flight" and _air_cast_locked:
		var origin := Vector2(facing*60,-90)
		var aim := (_air_aim+Vector2(0,-55)-position-origin).normalized()
		draw_line(origin,origin+aim*42,Color("f8c985"),2)
		draw_circle(origin,7,Color(1.0,0.65,0.22,0.35))
	if state=="windup":
		var color := Color("f56a52") if attack.get("heavy",false) else Color("ffe6a1")
		draw_circle(Vector2(0,-245 if kind=="buto" else -190),8,color)
		if attack.get("heavy",false):
			draw_line(Vector2(-7,-255),Vector2(7,-235),color,3)
			draw_line(Vector2(7,-255),Vector2(-7,-235),color,3)

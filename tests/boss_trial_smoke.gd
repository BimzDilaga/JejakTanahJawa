extends Node
var failures := 0
var arena: Node
var capture_dir := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--screenshots="):
			capture_dir = argument.trim_prefix("--screenshots=")
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame

func shot(label: String) -> void:
	if capture_dir.is_empty(): return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir.path_join(label+".png"))

func walk(x: float) -> void:
	var action := "move_right" if x>arena.player.position.x else "move_left"
	Input.action_press(action)
	var ticks := 0
	while absf(arena.player.position.x-x)>8 and ticks<500 and not arena.player.dead:
		await frames(1)
		ticks += 1
	Input.action_release(action)
	check(ticks<500 and not arena.player.dead,"Reach parkour position "+str(x))
	await frames(2)

func hop(x: float) -> void:
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	await walk(x)
	var ticks := 0
	while not arena.player.is_on_floor() and ticks<80 and not arena.player.dead:
		await frames(1)
		ticks += 1
	check(arena.player.is_on_floor(),"Land safely at "+str(x))

func load_arena(kind: String) -> void:
	GameState.boss_trial_kind = kind
	arena = load("res://boss_trial.tscn").instantiate()
	add_child(arena)
	await frames(70)
	check(arena.stage==arena.Stage.EXPLORE and arena.player.controls_enabled,"Spawn finishes in "+kind+" trial")
	check(arena.boss.health>0 and arena.boss_stance.max_value>0,"Boss has health and stance")
	check(arena.boss_music.stream!=null and arena.boss_music.stream.get_length()>30 and arena.boss_music.stream.loop,"Each arena has a decoded looping boss soundtrack")
	if kind=="buto":
		for animation in ["spawn","stagger","death"]:
			check(arena.boss.sprite.sprite_frames.get_frame_count(animation)==6 and not _boss_manifest().buto[animation].placeholder,"Buto uses six real frames for "+animation)
	check(not arena.day_night.clock_enabled and is_equal_approx(GameState.time_of_day,0.875),"Trial keeps its nighttime atmosphere")
	check(arena.boss_health.global_position.y>570 and arena.boss_health.size.y<20,"Boss bars stay below the action with compact height")
	check(arena.atmosphere.motes.size()==arena.atmosphere.LIMIT,"Ambient motes stay at a fixed budget")
	var fire: float = arena.day_night.filter_material.get_shader_parameter("fire_strength")
	check(fire>0.0 if kind=="banaspati" else is_zero_approx(fire),"Fire grading applies only to Banaspati")

func _run() -> void:
	preload("res://tests/test_session.gd").isolate("boss_trial_smoke.gd")
	GameState.reset_campaign()
	GameState.upgrade_levels.heart = 2
	var menu_scene: Node = load("res://bab_tegalrejo.tscn").instantiate()
	add_child(menu_scene)
	await frames(3)
	await shot("00-menu")
	menu_scene._show_boss_trials()
	var buttons: Array[String] = []
	for button in menu_scene.overlay.find_children("*","Button",true,false): buttons.append(button.text)
	check("Buto Ijo" in buttons and "Banaspati" in buttons and "Headless Swordsman" in buttons,"Main menu opens the boss trial chooser")
	menu_scene.queue_free()
	await frames(3)
	await load_arena("buto")
	await shot("01-buto-ready")
	arena.player.position = Vector2(600,570)
	arena.boss.position = Vector2(780,570)
	arena.player.reset_health()
	arena.boss.combo.assign([{"animation":"light","heavy":false,"effect":"melee"}])
	arena.boss.combo_index = 0
	arena.boss._begin_strike()
	await frames(31)
	check(arena.player.perform_parry(),"Player opens a timed parry for a real light attack")
	await frames(13)
	check(arena.player.health==5 and arena.player.stance==1 and arena.boss.stance==2,"Parrying a boss attack blocks damage and pressures boss stance")
	await shot("02-buto-parried")
	arena.player.reset_health()
	arena.player.position = Vector2(600,570)
	arena.boss.position = Vector2(780,570)
	arena.boss.combo.assign([{"animation":"heavy","heavy":true,"effect":"melee"}])
	arena.boss.combo_index = 0
	arena.boss._begin_strike()
	await frames(54)
	arena.player.perform_parry()
	await frames(12)
	check(arena.player.health==3 and arena.player.stance==2 and arena.boss.stance==2,"Trying to parry heavy takes damage and adds two stance load")
	check(arena.player.parry_cooldown>1.8,"Failed heavy parry starts the failure cooldown")
	arena.player.reset_health()
	arena.player.position = Vector2(600,570)
	arena.boss._strike()
	check(arena.player.health==3 and arena.player.stance==0,"Heavy without a parry attempt adds no stance penalty")
	arena.player.reset_health()
	arena.player.position = Vector2(600,570)
	arena.player.stance = 4
	arena.player.perform_parry()
	arena.boss._strike()
	check(arena.player.health==3 and arena.player.stance==5 and is_equal_approx(arena.player.stun_time,2.0),"Heavy parry overflow causes stance break and damage")
	arena.player.reset_health()
	for i in range(3): arena.boss.on_parried()
	await frames(28)
	check(arena.boss.state=="stagger_hold" and arena.boss.sprite.frame==5,"Stance break holds the final kneeling frame")
	await shot("03-buto-kneeling")
	await frames(220)
	check(arena.boss.state=="stagger_hold" and arena.boss.sprite.frame==5,"Boss remains kneeling for the four-second punish window")
	await frames(20)
	check(arena.boss.state=="stagger_out" and arena.boss.sprite.frame<5,"Recovery reverses the kneeling frames")
	await frames(30)
	check(arena.boss.stance==0,"Boss stance resets after getting up")
	arena.boss.set_physics_process(false)
	arena.player.position = arena.boss.position-Vector2(100,0)
	arena.player.facing = 1
	var hp: int = arena.boss.health
	arena.player.perform_attack()
	await frames(14)
	check(arena.boss.health<hp and arena.player.ultimate_charge==1,"Real keris hits damage the boss and charge ultimate")
	arena.player.reset_health()
	arena.player.perform_parry()
	arena._hazard(arena.boss,arena.player.position,Vector2.ZERO,false,true,42,"wave",0,0.2,30)
	await frames(3)
	check(arena.player.health==4 and arena.player.stance==2,"Buto earth wave also punishes attempted heavy parry with two stance load")
	arena.boss.set_physics_process(true)
	arena.boss.take_damage(999,arena.player.position.x)
	await frames(240)
	check(arena.boss.phase==2 and not arena.boss.dead,"Phase one knockdown returns as phase two")
	arena.boss.take_damage(999,arena.player.position.x)
	await frames(30)
	check(arena.stage==arena.Stage.COMPLETE and arena.boss.state_time>0.3,"Victory allows the death animation to keep playing")
	await shot("04-buto-defeated")
	arena._retry_trial()
	await frames(70)
	check(arena.player.health==5 and GameState.heal_stock==3 and get_tree().get_nodes_in_group("bosses").size()==1,"Retry restores one boss and trial supplies")
	arena.queue_free()
	await frames(3)
	await load_arena("banaspati")
	check(arena.platforms.size()==36 and arena.sounds.size()==9,"Banaspati has nine platforms per section and supplied sound effects")
	await shot("05-banaspati-ready")
	arena.boss.air_cooldown = 0.02
	arena.boss._set_state("idle")
	await frames(5)
	check(arena.chasing and arena.boss.state=="flight" and arena.boss.invulnerable,"Flight starts automatically when its ground cooldown expires")
	arena._retry_trial()
	await frames(70)
	arena.player.position = Vector2(1070,570)
	check(arena.begin_chase(),"Aerial chase starts")
	arena.boss.invulnerable = true
	arena.boss._set_state("flight")
	arena.boss._air_timer = 100
	var old_hp: int = arena.boss.health
	check(not arena.boss.take_damage(2,arena.player.position.x) and arena.boss.health==old_hp,"Airborne Banaspati is invulnerable")
	Input.action_press("sprint")
	await walk(1090)
	await hop(1210)
	await walk(1330)
	for index in range(1,9):
		var start := 1170+index*260
		await hop(start+30)
		if index==3:
			check(arena.flight_wall.visible and arena.rear_fire>=arena.player.position.x-365,"Tall fire wall keeps following across the long route")
			if not capture_dir.is_empty():
				arena.emit_boss_attack(arena.boss,"projectile")
				arena.emit_boss_attack(arena.boss,"pillar")
				await frames(3)
			await shot("06-banaspati-parkour")
			arena._clear_hazards()
		await walk(start+160)
	await hop(3540)
	check(arena.chasing and arena.boss.invulnerable,"Fire keeps herding the player until reaching safe ground")
	await walk(3610)
	Input.action_release("sprint")
	await frames(45)
	check(arena.sector==1 and not arena.chasing and not arena.boss.invulnerable,"Crossing all nine platforms brings Banaspati down on safe ground")
	check(arena.boss.air_cooldown>14 and arena.boss.air_cooldown<=16,"Landing resets the flight skill cooldown")
	await shot("08-banaspati-safe-ground")
	arena.boss.air_cooldown = 0.02
	arena.boss._set_state("idle")
	await frames(5)
	check(arena.chasing and arena.boss.invulnerable and arena.chase_end>8000,"The next cooldown starts another aerial survival section")
	arena.chasing = false
	arena.boss.invulnerable = false
	arena.boss._set_state("idle")
	check(arena.platforms[0].fallen and arena.platforms[1].fallen,"Platforms behind the player collapse")
	arena.boss.set_physics_process(false)
	arena.player.reset_health()
	arena.player.position = Vector2(4200,570)
	arena.player.perform_parry()
	arena._hazard(arena.boss,arena.player.position+Vector2(90,-55),Vector2(-260,0),true,false,15,"fx_2",0,3)
	await frames(20)
	check(arena.player.health==5 and arena.player.stance==1,"Small Banaspati projectile can be parried")
	var prior_stance: int = arena.boss.stance
	arena.player.perform_parry()
	arena._hazard(arena.boss,arena.player.position,Vector2.ZERO,false,true,48,"fx_6",0.1,0.7,180)
	await frames(15)
	check(arena.player.health==4 and arena.boss.stance==prior_stance,"Fire pillars bypass parry")
	await frames(45)
	arena.player.reset_health()
	Input.action_press("jump")
	await frames(10)
	Input.action_release("jump")
	arena._hazard(arena.boss,Vector2(arena.player.position.x-20,570),Vector2(210,0),false,true,42,"fx_5",0,2,30)
	await frames(5)
	check(arena.player.health==5,"Jumping clears a low flame wave")
	arena._clear_hazards()
	arena.chasing = true
	arena.chase_end = 8110
	arena.rear_fire = 5000
	arena.player.position = Vector2(5860,540)
	arena.player.velocity = Vector2.ZERO
	await frames(123)
	check(arena.platforms[9].phase==2 and not arena.platforms[9].fallen,"Standing too long warns before the platform falls")
	await frames(35)
	check(arena.platforms[9].fallen and arena.platforms[9].collider.disabled,"Collapse removes the real collision surface")
	arena._retry_trial()
	await frames(70)
	check(not arena.platforms[9].fallen and not arena.platforms[9].collider.disabled and arena.sector==0 and not arena.fire_wall_active,"Retry rebuilds the parkour route and removes the old fire wall")
	arena.sector = arena.built_modules-1
	var old_length: float = arena.length
	check(arena.begin_chase() and arena.length>old_length,"Route extends so flight cycles can continue beyond the initial sections")
	arena._retry_trial()
	await frames(70)
	arena._show_pause()
	var before: float = arena.boss.state_time
	await frames(15)
	check(is_equal_approx(arena.boss.state_time,before),"Pause stops boss combat")
	arena._close_overlay()
	arena.boss.take_damage(999,arena.player.position.x)
	await frames(240)
	arena.boss.take_damage(999,arena.player.position.x)
	await frames(30)
	check(arena.stage==arena.Stage.COMPLETE and arena.boss.state_time>0.3,"Banaspati death plays and completes the trial")
	await shot("07-banaspati-defeated")
	arena.queue_free()
	await frames(4)
	print("BOSS_TRIAL_SMOKE failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

func _boss_manifest() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/boss_assets.json"))

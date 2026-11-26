extends "res://scripts/chapter_one.gd"
const Boss = preload("res://scripts/urban_boss.gd")
const Hazard = preload("res://scripts/boss_hazard.gd")
const FallingPlatform = preload("res://scripts/collapsing_platform.gd")
const BossVisual = preload("res://scripts/boss_visual.gd")
const MODULE := 4600.0
const MODULES := 4
const GROUND_END := 1120.0
const SAFE_START := 3510.0
const PLATFORM_COUNT := 9
const SKY_PATH := "res://assets/Background/Forest/forest_sky.png"
var kind := "buto"
var boss: CharacterBody2D
var length := 1800.0
var sector := 0
var chasing := false
var chase_end := SAFE_START
var rear_fire := -200.0
var _rear_hit_time := 0.0
var platforms: Array[StaticBody2D] = []
var boss_health: ProgressBar
var boss_stance: ProgressBar
var boss_caption: Label
var _return_time := 0.625
var _return_heals := 0
var sounds: Dictionary = {}
var boss_music: AudioStreamPlayer
var sound_voices: Node2D
var rear_flames: AnimatedSprite2D
var depth_backdrop: Node2D
var flight_wall: Node2D
var route_end_wall: StaticBody2D
var built_modules := MODULES
var background_end := -2
var fire_wall_active := false
var phase_camera_locked := false
var _phase_controls_enabled := true
var _result_serial := 0
var _fire_level := FIRE_STRENGTH
var sound_definitions: Dictionary = {}
var _last_sound: Dictionary = {}
const FIRE_STRENGTH := 0.58

func _ready() -> void:
	kind = GameState.boss_trial_kind
	_return_time = GameState.time_of_day
	_return_heals = GameState.heal_stock
	GameState.start_on_load = false
	GameState.time_of_day = _return_time if kind=="commander" else 0.875
	GameState.heal_stock = 3
	if kind=="banaspati": length = MODULE*MODULES
	elif kind=="commander": length = 2400
	super._ready()
	day_night.clock_enabled = false
	day_night.filter_material.set_shader_parameter("fire_strength",FIRE_STRENGTH if kind=="banaspati" else 0.0)
	GameState.set_objective("Hadapi %s. Tanda merah berarti serangan tidak bisa di-parry." % boss_name())
	_load_sounds()
	sound_voices = Node2D.new()
	sound_voices.name = "BossSFX"
	world.add_child(sound_voices)
	boss_music = AudioStreamPlayer.new()
	boss_music.name = "BossMusic"
	boss_music.bus = "Music"
	boss_music.process_mode = Node.PROCESS_MODE_PAUSABLE
	boss_music.volume_db = -22.0
	var music_file: String = {"buto":"buto-akusara.ogg","banaspati":"banaspati-fight-fire.ogg","headless":"headless-smoke-and-bronze.ogg","commander":"commander-last-march.ogg"}[kind]
	boss_music.stream = load("res://assets/Generated/Audio/Music/"+music_file)
	(boss_music.stream as AudioStreamOggVorbis).loop = true
	add_child(boss_music)
	if DisplayServer.get_name()!="headless": boss_music.play()
	if kind=="banaspati":
		play_banaspati_sound("spawn",boss.position)
		play_banaspati_sound("roar",boss.position)
	elif kind=="headless": play_headless_sound("spawn",boss.position)
	else: play_buto_sound("spawn",boss.position)

func _set_menu() -> void:
	stage = Stage.INTRO
	menu.hide()
	hud.show()
	player.controls_enabled = false

func _build_world() -> void:
	var backdrop := CanvasLayer.new()
	backdrop.layer = -10
	add_child(backdrop)
	var sky := TextureRect.new()
	sky.texture = load(SKY_PATH if kind=="banaspati" else "res://assets/Background/Tegalrejo/tegalrejo_sky.png")
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.size = Vector2(1280,720)
	backdrop.add_child(sky)
	world = Node2D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	depth_backdrop = Node2D.new()
	depth_backdrop.z_index = -10
	world.add_child(depth_backdrop)
	mountains = Node2D.new()
	world.add_child(mountains)
	_extend_backdrops()
	player = preload("res://player.tscn").instantiate()
	player.world_right = length-50
	player.position = Vector2(270,FLOOR_Y)
	world.add_child(player)
	cat = _make_cat(Vector2(200,FLOOR_Y-56))
	if kind!="banaspati":
		_ground(0,length)
	else:
		for i in range(MODULES): _build_module(i)
		rear_flames = _flame_sprite()
		rear_flames.scale = Vector2(1,2)
		rear_flames.hide()
		world.add_child(rear_flames)
		flight_wall = Node2D.new()
		flight_wall.name = "ChasingFireWall"
		flight_wall.z_index = 3
		world.add_child(flight_wall)
		# Reuse the supplied flame as three overlapping columns, 620 pixels tall.
		for offset in [-230.0,-160.0,-90.0]:
			var flame := _flame_sprite()
			# Bury the faint source-image fringe below the walking surface.
			flame.position = Vector2(offset,-584)
			var size := flame.sprite_frames.get_frame_texture("fx_8",0).get_size()
			flame.scale = Vector2(110.0/size.x,620.0/size.y)
			flame.frame = posmod(int(offset),flame.sprite_frames.get_frame_count("fx_8"))
			flight_wall.add_child(flame)
		flight_wall.hide()
	_solid(Vector2(-20,400),Vector2(40,1000))
	_solid(Vector2(length+20,400),Vector2(40,1000))
	route_end_wall = world.get_child(world.get_child_count()-1)
	camera = Camera2D.new()
	camera.position = Vector2(640,CAMERA_Y)
	camera.zoom = Vector2.ONE*1.1
	camera.limit_left = 0
	camera.limit_right = int(length)
	camera.limit_top = 0
	camera.limit_bottom = 800
	world.add_child(camera)
	_spawn_boss()

func _flame_sprite() -> AnimatedSprite2D:
	var flame := AnimatedSprite2D.new()
	flame.sprite_frames = BossVisual.effects("banaspati","fx_8")
	flame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flame.centered = false
	flame.z_index = 3
	flame.play("fx_8")
	return flame

func _build_module(index: int) -> void:
	var settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/boss_tuning.json")).banaspati
	var base := index*MODULE
	_ground(base,GROUND_END)
	_ground(base+SAFE_START,MODULE-SAFE_START)
	for number in range(PLATFORM_COUNT):
		var platform := FallingPlatform.new()
		platform.position = Vector2(base+1170+number*260,[540,500,540][number%3])
		platform.target = player
		platform.arena = self
		platform.stand_seconds = float(settings.platform_stand_seconds)
		platform.warning_seconds = float(settings.platform_warning_seconds)
		world.add_child(platform)
		platforms.append(platform)

func _extend_backdrops() -> void:
	if kind=="commander":
		var texture: Texture2D = load("res://assets/Generated/Magelang/town-panorama-v1.png")
		var factor := 0.85
		var step := texture.get_width()*factor-2.0
		for index in range(background_end+1,ceili(length/step)+2):
			var tile := Sprite2D.new()
			var crop := AtlasTexture.new()
			crop.atlas = texture
			crop.region = Rect2(0,220,2172,504)
			tile.texture = crop
			tile.centered = false
			tile.position = Vector2(index*step,213)
			tile.scale = Vector2.ONE*factor
			tile.flip_h = posmod(index,2)==1
			var material := ShaderMaterial.new()
			material.shader = preload("res://shaders/background_top_fade.gdshader")
			tile.material = material
			depth_backdrop.add_child(tile)
		background_end = ceili(length/step)+1
		return
	var last_tile := ceili(length/1735)+1
	for i in range(background_end+1,last_tile+1):
		var far_tile: Sprite2D
		if kind=="banaspati":
			far_tile = _region_sprite(depth_backdrop,"res://assets/Background/Forest/forest_distant_trees.png",Rect2(0,0,2172,724),Vector2(i*1735,-160),Vector2(0.8,1.5))
		else:
			far_tile = _region_sprite(depth_backdrop,"res://assets/Background/Tegalrejo/tegalrejo_mountains.png",Rect2(0,330,2172,300),Vector2(i*1735,245),Vector2(0.8,1.1))
		far_tile.flip_h = posmod(i,2)==1
		var background := "res://assets/Background/Forest/forest_midground.png.png" if kind=="banaspati" else "res://assets/Background/Tegalrejo/tegalrejo_village.png"
		if kind=="headless": background = "res://assets/Background/Permukiman Terdampak Perang/Abandoned Rustic Village Panorama.png"
		var near_tile: Sprite2D
		if kind=="headless":
			near_tile = _region_sprite(mountains,background,Rect2(0,0,2172,724),Vector2(i*1735,18),Vector2(0.8,0.8))
			var cutout := ShaderMaterial.new()
			cutout.shader = preload("res://shaders/prop_cutout.gdshader")
			near_tile.material = cutout
		elif kind!="banaspati":
			near_tile = _region_sprite(mountains,background,Rect2(0,265,2172,355),Vector2(i*1735,266),Vector2(0.8,0.9))
		else:
			near_tile = _region_sprite(mountains,background,Rect2(0,0,2172,724),Vector2(i*1735,0),Vector2(0.8,0.8))
			var fade := ShaderMaterial.new()
			fade.shader = preload("res://shaders/background_edge.gdshader")
			near_tile.material = fade
		near_tile.flip_h = posmod(i,2)==1
	background_end = last_tile

func _ground(x: float, width: float) -> void:
	_solid(Vector2(x+width/2,670),Vector2(width,200))
	_ground_art(x,width)

func _spawn_boss() -> void:
	if kind=="headless": boss = preload("res://scripts/headless_boss.gd").new()
	elif kind=="commander": boss = preload("res://scripts/commander_boss.gd").new()
	else: boss = Boss.new()
	boss.kind = kind
	boss.arena = self
	boss.target = player
	boss.position = Vector2(820 if kind=="buto" else 720,FLOOR_Y)
	world.add_child(boss)
	boss.defeated.connect(_boss_defeated)
	boss.phase_transition_started.connect(_phase_transition_started)
	boss.phase_changed.connect(_phase_changed)

func _build_ui() -> void:
	super._build_ui()
	chapter_steps.text = "MAGELANG" if kind=="commander" else "LEGENDA"
	var heading := "PERTEMUAN MALAM" if is_instance_valid(GameState.encounter_chapter) else "ARENA UJI"
	if kind=="commander" and is_instance_valid(GameState.encounter_chapter): heading = "BAB 5"
	_relabel(ui,"01  /  TEGALREJO",heading+"  /  "+boss_name().to_upper())
	var panel := _panel(hud,Rect2(298,578,684,74),Color("142b2af2"))
	boss_caption = _label(panel,"",Rect2(12,5,660,22),14,GOLD)
	boss_health = _bar(panel,Vector2(12,30),Color("b85f4f"))
	boss_stance = _bar(panel,Vector2(12,51),Color("d9b56d"))
	notice.position = Vector2(28,145)
	notice.size = Vector2(570,58)
	notice.add_theme_font_size_override("font_size",16)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu.hide()

func _bar(parent: Control, at: Vector2, tint: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = at
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for entry in ["background","fill"]:
		var style := _style(Color("344b44") if entry=="background" else tint,Color.TRANSPARENT,3)
		style.set_content_margin_all(0)
		bar.add_theme_stylebox_override(entry,style)
	parent.add_child(bar)
	bar.size = Vector2(660,13)
	return bar

func _relabel(node: Node, old: String, replacement: String) -> void:
	if (node is Label or node is Button) and node.text==old:
		node.text = replacement
	for child in node.get_children(): _relabel(child,old,replacement)

func _process(delta: float) -> void:
	if paused or not is_instance_valid(player) or not is_instance_valid(boss):
		return
	elapsed += delta
	if stage==Stage.INTRO and boss.state!="spawn":
		stage = Stage.EXPLORE
		player.controls_enabled = true
		_notify("Bertarung di tanah. Saat Banaspati terbang, lari dari tembok api!" if kind=="banaspati" else "Klik kanan: parry  •  H: heal  •  L: ulti  •  T: bantuan")
	var half_width := 640/1.1
	var focus := boss.position.x if phase_camera_locked else player.position.x+150
	camera.position.x = lerpf(camera.position.x,clampf(focus,half_width,length-half_width),1-exp(-delta*5))
	camera.position.y = lerpf(camera.position.y,380.0 if kind=="banaspati" and chasing else CAMERA_Y,1-exp(-delta*4))
	mountains.position.x = (camera.position.x-half_width)*0.12
	depth_backdrop.position.x = (camera.position.x-half_width)*0.32
	if kind=="banaspati":
		var origin := get_viewport().get_canvas_transform()*(boss.global_position+Vector2(0,-100))
		day_night.filter_material.set_shader_parameter("fire_origin",origin/get_viewport_rect().size)
		_fire_level = lerpf(_fire_level,FIRE_STRENGTH+(0.07 if chasing else 0.0)+(0.04 if boss.phase>=2 else 0.0),1-exp(-delta*2))
		day_night.filter_material.set_shader_parameter("fire_strength",_fire_level)
		day_night.filter_material.set_shader_parameter("fire_pulse",1.0+sin(elapsed*3.1)*0.035)
		atmosphere.heat = lerpf(atmosphere.heat,1.0 if chasing else 0.4,1-exp(-delta*2))
	var cat_target := player.position+Vector2(-player.facing*65,-56)
	var cat_moving := cat.position.distance_to(cat_target)>12
	cat.position = cat.position.lerp(cat_target,1-exp(-delta*4))
	cat.flip_h = player.facing<0
	_update_cat_animation(cat_moving,not player.is_on_floor())
	boss_caption.text = "%s • FASE %d/%d • HP %d/%d • STANCE %d/%d%s" % [boss_name().to_upper(),boss.phase,int(boss.tuning.phase_count),boss.health,boss.max_health,boss.stance,boss.stance_max," • KEBAL" if boss.invulnerable else ""]
	if kind=="banaspati" and not boss.invulnerable:
		boss_caption.text += "   •   TERBANG %.0f dtk" % boss.air_cooldown
	boss_health.max_value = boss.max_health
	boss_health.value = boss.health
	boss_stance.max_value = boss.stance_max
	boss_stance.value = boss.stance
	if is_instance_valid(rear_flames):
		rear_flames.visible = stage==Stage.EXPLORE and not chasing
		rear_flames.position = Vector2(sector*MODULE+GROUND_END,570-rear_flames.sprite_frames.get_frame_texture("fx_8",rear_flames.frame).get_height()*2)
		flight_wall.visible = fire_wall_active and stage==Stage.EXPLORE
		flight_wall.position = Vector2(rear_fire,FLOOR_Y)
		for flame in flight_wall.get_children():
			if flame is AnimatedSprite2D:
				var frame_size: Vector2 = flame.sprite_frames.get_frame_texture("fx_8",flame.frame).get_size()
				flame.scale = Vector2(110.0/frame_size.x,620.0/frame_size.y)
	if stage==Stage.EXPLORE:
		if player.position.y>850:
			player.invulnerable_time = 0
			player.take_damage(player.max_health,player.position.x,false)
		if kind=="banaspati":
			_rear_hit_time = maxf(0,_rear_hit_time-delta)
			if not chasing and not phase_camera_locked:
				player.position.x = minf(player.position.x,sector*MODULE+GROUND_END-30)
			if chasing:
				rear_fire += float(boss.tuning.rear_fire_speed)*delta
				rear_fire = minf(chase_end-50,maxf(rear_fire,player.position.x-float(boss.tuning.rear_fire_max_distance)))
				if int(elapsed*20)%3==0:
					player.effects.embers(Vector2(rear_fire-30,randf_range(40,550)),3)
			if fire_wall_active and player.position.x<rear_fire+24 and _rear_hit_time<=0:
				player.take_damage(1,rear_fire,false)
				_rear_hit_time = 1.1
	if notice_time>0:
		notice_time -= delta
		notice.visible = notice_time>0
	queue_redraw()

func ground_boss_limit() -> float:
	return sector*MODULE+GROUND_END-90 if kind=="banaspati" else length-70

func begin_chase() -> bool:
	if kind!="banaspati" or chasing:
		return false
	# Add another full section before reaching the last one; flight can repeat until victory.
	if sector>=built_modules-1:
		_build_module(built_modules)
		built_modules += 1
		length = built_modules*MODULE
		player.world_right = length-50
		camera.limit_right = int(length)
		route_end_wall.position.x = length+20
		_extend_backdrops()
	chasing = true
	chase_end = sector*MODULE+SAFE_START
	rear_fire = maxf(rear_fire,player.position.x-300) if fire_wall_active else player.position.x-300
	fire_wall_active = true
	_notify("BERTAHAN! Banaspati kebal. Terus lari dan lompat, tembok api mengejar!")
	return true

func announce_landing() -> void:
	_notify("Banaspati turun! Terus maju ke tanah aman untuk bertarung kembali.")

func finish_chase() -> void:
	chasing = false
	sector += 1
	rear_fire = chase_end-50
	_clear_hazards()
	_notify("Tanah aman! Banaspati bisa diserang sampai skill terbangnya siap lagi.")

func emit_boss_attack(attacker: CharacterBody2D, effect: String, aimed_at: Vector2 = Vector2.INF) -> void:
	var aim: Vector2 = attacker.attack.get("aim_point",player.position) if aimed_at==Vector2.INF else aimed_at
	var tempo: float = attacker.tempo()
	if kind=="commander":
		var origin := attacker.position+Vector2(attacker.facing*60,-100)
		var direction := (aim+Vector2(0,-55)-origin).normalized()
		var count := 3 if effect=="rapid" else (5 if effect=="finalsalvo" else 1)
		for index in range(count):
			var angle := (index-2)*0.10 if effect=="finalsalvo" else 0.0
			var hazard := _hazard(attacker,origin,direction.rotated(angle)*float(attacker.tuning.projectile_speed),true,false,8,"bullet",index*0.16/tempo,4.0)
			hazard.knockback = float(attacker.tuning.light_knockback)
		return
	if effect in ["mark","pillar","dive"]:
		var count := 2 if effect=="mark" else 1
		for index in range(count):
			var x := aim.x+index*140.0
			if effect=="dive": x = clampf(aim.x,attacker.position.x-165,attacker.position.x+165)
			var warning := float(attacker.tuning.get("pillar_warning",0.75))/tempo+index*0.18
			var fx := "fx_7" if effect=="dive" else "fx_6"
			var hazard := _hazard(attacker,Vector2(x,_surface_y(x)),Vector2.ZERO,false,true,48,fx,warning,warning+0.9,180 if effect!="dive" else 90)
			hazard.damage = int(attacker.tuning.heavy_damage)
			hazard.knockback = float(attacker.tuning.get("heavy_knockback",380))
		play_banaspati_sound("impact" if effect=="dive" else "cast",attacker.position)
	elif effect in ["wave","earth_wave"]:
		var hazard := _hazard(attacker,attacker.position+Vector2(attacker.facing*70,0),Vector2(attacker.facing*210,0),false,true,42,"wave" if effect=="earth_wave" else "fx_5",0.15,4,30)
		hazard.visual_kind = "buto" if effect=="earth_wave" else "banaspati"
		hazard.damage = int(attacker.tuning.heavy_damage)
		hazard.knockback = float(attacker.tuning.get("heavy_knockback",380))
		if effect=="earth_wave": play_buto_sound("wave",attacker.position)
	else:
		var origin := attacker.position+Vector2(attacker.facing*60,-90)
		var direction := (aim+Vector2(0,-55)-origin).normalized()
		for angle in [-0.30,0.0,0.30] if effect=="spread" else [0.0]:
			var hazard := _hazard(attacker,origin,direction.rotated(float(angle))*float(attacker.tuning.get("projectile_speed",260))*(1.1 if attacker.phase>=2 else 1.0),true,false,15,"fx_2",0.0,5)
			hazard.knockback = float(attacker.tuning.get("light_knockback",250))
		play_banaspati_sound("cast",attacker.position)

func _hazard(attacker: CharacterBody2D, at: Vector2, motion: Vector2, parry: bool, ground: bool, radius: float, fx: String, warning: float, lifetime: float, height := 130.0) -> Node2D:
	var hazard := Hazard.new()
	hazard.owner_boss = attacker
	hazard.target = player
	hazard.position = at
	hazard.motion = motion
	hazard.parryable = parry
	hazard.ground_hazard = ground
	hazard.radius = radius
	hazard.effect_name = fx
	hazard.visual_kind = "commander" if fx=="bullet" else ("buto" if fx=="wave" else "banaspati")
	hazard.warning = warning
	hazard.lifetime = lifetime
	hazard.hazard_height = height
	world.add_child(hazard)
	return hazard

func _clear_hazards() -> void:
	for hazard in get_tree().get_nodes_in_group("trial_hazards"): hazard.queue_free()

func _surface_y(x: float) -> float:
	for platform in platforms:
		if not platform.fallen and x>=platform.home.x and x<=platform.home.x+platform.width:
			return platform.home.y
	return FLOOR_Y

func _boss_defeated(_boss: Node) -> void:
	_result_serial += 1
	var serial := _result_serial
	boss_music.stop()
	if is_instance_valid(GameState.encounter_chapter): GameState.night_boss_defeated[kind] = true
	GameState.request_save()
	stage = Stage.COMPLETE
	GameState.ending_started = true
	player.controls_enabled = false
	chasing = false
	_clear_hazards()
	await get_tree().create_timer(1.25).timeout
	if serial!=_result_serial or not is_inside_tree(): return
	var subtitle := "Kembali kepada warga yang menunjukkan jalannya." if is_instance_valid(GameState.encounter_chapter) else "Arena uji selesai. HP, damage, dan beberapa pose masih sementara."
	var box := _new_overlay("result","%s dikalahkan" % boss_name(),subtitle)
	_button(box,"Coba lagi",Rect2(40,210,780,58),_retry_trial,true)
	_button(box,_return_caption(),Rect2(40,292,780,58),_return_menu)

func _on_player_died() -> void:
	boss_music.stop()
	stage = Stage.FAILED
	GameState.ending_started = true
	chasing = false
	var box := _new_overlay("result","Coba kembali","Baca ancang-ancang. Serangan bertanda merah harus dihindari.")
	_button(box,"Ulangi arena",Rect2(40,210,780,58),_retry_trial,true)
	_button(box,_return_caption(),Rect2(40,292,780,58),_return_menu)

func _retry_trial() -> void:
	_result_serial += 1
	phase_camera_locked = false
	_last_sound.clear()
	get_tree().paused = false
	paused = false
	GameState.ending_started = false
	GameState.dialogue_active = false
	GameState.heal_stock = 3
	overlay.hide()
	_clear_hazards()
	sector = 0
	fire_wall_active = false
	_clear_sound_voices()
	chasing = false
	_rear_hit_time = 0
	for platform in platforms: platform.reset_platform()
	if is_instance_valid(boss):
		boss.active = false
		boss.remove_from_group("enemies")
		boss.remove_from_group("bosses")
		boss.queue_free()
	player.reset_health()
	player.position = Vector2(270,FLOOR_Y)
	player.controls_enabled = false
	_spawn_boss()
	if DisplayServer.get_name()!="headless": boss_music.play()
	if kind=="banaspati": play_banaspati_sound("roar",boss.position)
	elif kind=="headless": play_headless_sound("spawn",boss.position)
	else: play_buto_sound("spawn",boss.position)
	stage = Stage.INTRO

func _show_pause() -> void:
	paused = true
	get_tree().paused = true
	var box := _new_overlay("pause","Arena dijeda","Lanjutkan pertarungan atau mulai ulang arena.")
	_button(box,"Lanjut",Rect2(40,190,780,58),_close_overlay,true)
	_button(box,"Ulangi arena",Rect2(40,270,780,58),_retry_trial)
	_button(box,_return_caption(),Rect2(40,350,780,58),_return_menu)

func _show_journal() -> void:
	paused = true
	get_tree().paused = true
	var box := _new_overlay("journal","Petunjuk pertarungan","Baca ancang-ancang boss. Tangkis serangan ringan dan hindari tanda merah.")
	_paragraph(box,"Klik kiri: combo keris  •  Klik kanan: parry  •  H: heal  •  L: ulti\nShift: dash lalu tahan untuk lari  •  S + Shift: dash mundur\nDash tetap bisa terkena serangan; cooldown bersama 1 detik.\n\nLima stance Jaka adalah batas aman. Satu poin pulih setiap detik.\nMencoba parry heavy Buto Ijo: +2 beban stance dan tetap terkena damage.\nTanda merah: hindari serangannya. Saat boss berlutut, serang balik.\n\nBanaspati terbang: ia kebal. Lewati sembilan platform dan tembok api.\nBertarung lagi setelah keduanya di tanah aman.",Rect2(40,180,780,300),17,PAPER)
	_button(box,"Kembali",Rect2(40,490,780,58),_close_overlay)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo(): return
	if event.is_action_pressed("pause"):
		if paused: _close_overlay()
		elif stage==Stage.EXPLORE: _show_pause()
	elif event.is_action_pressed("journal") and stage==Stage.EXPLORE and not paused:
		_show_journal()

func _return_menu() -> void:
	_result_serial += 1
	get_tree().paused = false
	GameState.time_of_day = _return_time
	GameState.heal_stock = _return_heals
	GameState.ending_started = false
	GameState.start_on_load = false
	if GameState.return_from_encounter(self): return
	get_tree().change_scene_to_file("res://bab_tegalrejo.tscn")

func _return_caption() -> String:
	return "Kembali ke perjalanan" if is_instance_valid(GameState.encounter_chapter) else "Kembali ke menu"

func _load_sounds() -> void:
	sounds.clear()
	if kind=="commander":
		var path := "res://assets/Generated/Audio/Temporary/flintlock-shot.wav"
		if ResourceLoader.exists(path): sounds["shot"] = load(path)
		return
	if kind in ["buto","headless"]:
		var pack: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/"+("buto" if kind=="buto" else "headless")+"_sfx.json"))
		sound_definitions = pack.clips
		for key in sound_definitions:
			var file: String = str(pack.root)+str(sound_definitions[key].file)
			if ResourceLoader.exists(file):
				var stream: AudioStream = load(file)
				stream.set_meta("combat_volume_db",float(sound_definitions[key].volume_db))
				sounds[key] = stream
		return
	var mapping := {"spawn":"01_fire_ignition_natural.wav","rise":"03_rising_into_air_natural.wav","cast":"02_fire_projectile_launch_natural.wav","break":"05_boss_stance_break_natural.wav","impact":"04_fiery_dive_impact_natural.wav","crack":"06_wooden_platform_cracking_natural.wav","collapse":"07_platform_collapsing_natural.wav","roar":"01_Banaspati_Beast_Fury_Roar.wav","laugh":"02_Banaspati_Demonic_Beast_Laugh.wav"}
	for key in mapping:
		var path := "res://assets/Generated/Audio/Banaspati/"+str(mapping[key])
		if ResourceLoader.exists(path): sounds[key] = load(path)

func play_banaspati_sound(key: String, at: Vector2) -> void:
	if kind!="banaspati" or not sounds.has(key): return
	_play_sound(key,at,-18 if key in ["roar","laugh"] else -14)

func play_buto_sound(key: String, at: Vector2) -> bool:
	if kind!="buto" or not sounds.has(key): return false
	var definition: Dictionary = sound_definitions[key]
	var now := Time.get_ticks_msec()/1000.0
	if now-float(_last_sound.get(key,-100))<float(definition.cooldown): return false
	_last_sound[key] = now
	return _play_sound(key,at,float(definition.volume_db))

func play_commander_sound(key: String, at: Vector2) -> void:
	if kind=="commander" and sounds.has(key): _play_sound(key,at,-19)

func play_headless_sound(key: String, at: Vector2) -> bool:
	if kind!="headless" or not sounds.has(key): return false
	var definition: Dictionary = sound_definitions[key]
	var now := Time.get_ticks_msec()/1000.0
	if now-float(_last_sound.get(key,-100))<float(definition.cooldown): return false
	_last_sound[key] = now
	return _play_sound(key,at,float(definition.volume_db))

func _play_sound(key: String, at: Vector2, volume: float) -> bool:
	if DisplayServer.get_name()=="headless": return false
	if sound_voices.get_child_count()>=12: return false
	var audio := AudioStreamPlayer2D.new()
	audio.bus = "SFX"
	audio.name = "BossAudio"
	audio.stream = sounds[key]
	audio.position = at
	audio.volume_db = volume
	audio.max_distance = 1500
	sound_voices.add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()
	return true

func _clear_sound_voices() -> void:
	# A dedicated container also includes voices Godot automatically renamed.
	for audio: AudioStreamPlayer2D in sound_voices.get_children():
		audio.stop()
		sound_voices.remove_child(audio)
		audio.queue_free()

func _phase_transition_started() -> void:
	phase_camera_locked = true
	_phase_controls_enabled = player.controls_enabled
	player.controls_enabled = false
	_clear_hazards()
	_notify("Belum selesai… %s akan bangkit!" % boss_name())

func _phase_changed(_phase: int) -> void:
	phase_camera_locked = false
	player.controls_enabled = _phase_controls_enabled
	if kind=="buto": play_buto_sound("spawn",boss.position)
	elif kind=="headless": play_headless_sound("spawn",boss.position)
	_notify("FASE 2 — tempo pertarungan meningkat!")

func boss_name() -> String:
	return {"buto":"Buto Ijo","banaspati":"Banaspati","headless":"Headless Swordsman","commander":"Komandan Belanda"}.get(kind,kind)

func _draw() -> void:
	pass

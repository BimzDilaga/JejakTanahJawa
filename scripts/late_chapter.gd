extends "res://scripts/chapter_one.gd"
## Story chapters keep regular patrols optional; only the final commander gates the ending.
var chapter_number := 4
var length := 6200.0
var hut_position := 550.0
var optional_patrol_positions: Array = [2050,4250,5500]
var mission := 0
var nearest := -1
var checkpoint := Vector2(600,570)
var markers: Array[Dictionary] = []
var panorama: Node2D
var location_label: Label
var ending_director: CanvasLayer

func _ready() -> void:
	GameState.start_on_load = false
	super._ready()
	story = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_%s.json" % ("four" if chapter_number==4 else "five")))
	start_chapter()

func _set_menu() -> void:
	menu.hide()
	hud.show()
	player.controls_enabled = false

func _build_world() -> void:
	if chapter_number==5: optional_patrol_positions = [2050,2700,3800,4400]
	var backdrop := CanvasLayer.new()
	backdrop.layer = -10
	add_child(backdrop)
	var sky := TextureRect.new()
	sky.texture = load("res://assets/Background/Permukiman Terdampak Perang/Moody Pixel-Art Cloudscape at Dusk.png" if chapter_number==4 else "res://assets/Background/Tegalrejo/tegalrejo_sky.png")
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.size = Vector2(1280,720)
	backdrop.add_child(sky)
	world = Node2D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	panorama = Node2D.new()
	panorama.name = "TownPanorama"
	panorama.z_index = -10
	world.add_child(panorama)
	mountains = panorama
	var path := "res://assets/Background/Permukiman Terdampak Perang/Abandoned Rustic Village Panorama.png" if chapter_number==4 else "res://assets/Generated/Magelang/town-panorama-v1.png"
	var region := Rect2(0,0,2172,724) if chapter_number==4 else Rect2(0,220,2172,504)
	var factor := 0.8 if chapter_number==4 else 0.85
	var top := 18.0 if chapter_number==4 else 213.0
	var step := region.size.x*factor-2
	for index in range(-1,ceili(length/step)+3):
		var tile := _region_sprite(panorama,path,region,Vector2(index*step,top),Vector2.ONE*factor)
		tile.flip_h = posmod(index,2)==1
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/prop_cutout.gdshader") if chapter_number==4 else preload("res://shaders/background_top_fade.gdshader")
		tile.material = material
	_ground_art(-100,length+200)
	_solid(Vector2(length/2,FLOOR_Y+100),Vector2(length+400,200))
	_solid(Vector2(-30,400),Vector2(60,1000))
	_solid(Vector2(length+30,400),Vector2(60,1000))
	# Optional raised routes let the player avoid exchanging fire with the patrols.
	for x in optional_patrol_positions:
		_ledge(Rect2(float(x)-260,515,130,20))
		_ledge(Rect2(float(x)-100,455,260,20))
		_ledge(Rect2(float(x)+190,515,130,20))
	player = preload("res://player.tscn").instantiate()
	player.position = Vector2(220,FLOOR_Y)
	player.world_right = length-40
	world.add_child(player)
	cat = _make_cat(Vector2(150,FLOOR_Y-56))
	camera = Camera2D.new()
	camera.position = Vector2(CAMERA_HALF_WIDTH,CAMERA_Y)
	camera.zoom = Vector2.ONE*CAMERA_ZOOM
	camera.limit_left = 0
	camera.limit_right = int(length)
	camera.limit_top = 0
	camera.limit_bottom = 800
	world.add_child(camera)
	if chapter_number==4:
		_npc("Tetua desa","res://assets/Karakter/sesepuh.png",ActorVisual.REGIONS["sesepuh.png"],1250)
		_npc("Warga","res://assets/Karakter/NPC Ibu2.png",ActorVisual.REGIONS["NPC Ibu2.png"],2850)
		_npc("Sari",SARI_IMAGE,SARI_REGION,4800)
		markers = [{"id":"elder","caption":"Dengar kabar tetua","at":Vector2(1250,520)},{"id":"family","caption":"Bantu keluarga warga","at":Vector2(2850,520)},{"id":"report","caption":"Sampaikan kabar ke Sari","at":Vector2(4800,520)},{"id":"exit","caption":"Lanjutkan perjalanan","at":Vector2(6030,520)}]
	else:
		_npc("Penunjuk jalan","res://assets/Karakter/NPC cwo.png",ActorVisual.REGIONS["NPC cwo.png"],1300)
		_npc("Sari",SARI_IMAGE,SARI_REGION,5100)
		markers = [{"id":"guide","caption":"Cari jalan keluar kota","at":Vector2(1300,520)},{"id":"commander","caption":"Hadapi komandan","at":Vector2(5100,520)}]

func _ledge(bounds: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = bounds.position
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = bounds.size
	collision.shape = shape
	collision.position = bounds.size/2
	collision.one_way_collision = true
	body.add_child(collision)
	world.add_child(body)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/selarong_art.json")).platform
	var region: Array = data.region
	var atlas := AtlasTexture.new()
	atlas.atlas = load(data.path)
	atlas.region = Rect2(region[0],region[1],region[2],region[3])
	var art := Sprite2D.new()
	art.centered = false
	art.texture = atlas
	var factor := bounds.size.x/float(region[2])
	art.scale = Vector2.ONE*factor
	art.position = bounds.position-Vector2(0,float(data.surface_from_top)*factor)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.add_child(art)

func _build_ui() -> void:
	super._build_ui()
	_relabel(ui,"01  /  TEGALREJO","04  /  DESA TERDAMPAK" if chapter_number==4 else "05  /  MAGELANG")
	chapter_steps.text = "1825–1830" if chapter_number==4 else "MARET 1830"
	location_label = _label(hud,"",Rect2(32,139,650,28),18,GOLD)
	location_label.text = "Kabar warga" if chapter_number==4 else "Jalan keluar Magelang"
	notice.position = Vector2(28,180)
	notice.size = Vector2(570,62)
	notice.add_theme_font_size_override("font_size",16)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.position = Vector2(390,574)
	menu.hide()

func _relabel(node: Node, old: String, replacement: String) -> void:
	if (node is Label or node is RichTextLabel or node is Button) and node.text==old: node.text = replacement
	for child in node.get_children(): _relabel(child,old,replacement)

func start_chapter() -> void:
	stage = Stage.INTRO
	player.controls_enabled = false
	GameState.set_objective("Temui tetua desa." if chapter_number==4 else "Temui penunjuk jalan.")
	_start_dialogue(story.intro,func() -> void:
		stage = Stage.EXPLORE
		player.controls_enabled = true
		_notify("Patroli biasa boleh dilewati. Kalahkan tentara jika ingin mengumpulkan poin."))

func _process(delta: float) -> void:
	if paused or not is_instance_valid(player): return
	elapsed += delta
	if GameState.dialogue_active:
		typing += delta*48
		dialogue_label.visible_characters = int(typing)
	camera.position.x = lerpf(camera.position.x,clampf(player.position.x+150,CAMERA_HALF_WIDTH,length-CAMERA_HALF_WIDTH),1-exp(-delta*5))
	panorama.position.x = (camera.position.x-CAMERA_HALF_WIDTH)*0.12
	var goal := player.position+Vector2(-player.facing*70,-56)
	var moving := cat.position.distance_to(goal)>12
	cat.position = cat.position.lerp(goal,1-exp(-delta*4))
	cat.flip_h = player.facing<0
	_update_cat_animation(moving,not player.is_on_floor())
	nearest = -1
	var best := 130.0
	for index in range(markers.size()):
		var distance: float = (player.position-Vector2(0,50)).distance_to(markers[index].at)
		if distance<best:
			best = distance
			nearest = index
	prompt.text = "[ E ]  "+str(markers[nearest].caption) if nearest>=0 and not GameState.dialogue_active else ""
	if notice_time>0:
		notice_time -= delta
		notice.visible = notice_time>0
	if chapter_number==5 and mission==2 and GameState.night_boss_defeated.get("commander",false) and not GameState.dialogue_active:
		mission = 3
		facts_unlocked = 3
		_start_dialogue(story.after,_ending_choice)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo(): return
	if event.is_action_pressed("interact"):
		if not paused and not overlay.visible:
			if GameState.dialogue_active: advance_dialogue()
			elif stage==Stage.EXPLORE and nearest>=0: _interact(str(markers[nearest].id))
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func _interact(id: String) -> void:
	if chapter_number==4:
		if id=="elder":
			_start_dialogue(story.elder,func() -> void:
				mission = maxi(mission,1)
				facts_unlocked = maxi(facts_unlocked,1)
				GameState.set_objective("Temui keluarga warga di ujung jalan."))
		elif id=="family" and mission>=1:
			_start_dialogue(story.family,func() -> void:
				mission = maxi(mission,2)
				facts_unlocked = maxi(facts_unlocked,2)
				GameState.story_notes["warga_desa"] = true
				GameState.set_objective("Sampaikan kabar keluarga kepada Sari."))
		elif id=="report" and mission>=2:
			_start_dialogue(story.report,func() -> void:
				mission = 3
				facts_unlocked = 3
				GameState.set_objective("Ikuti jalan menuju Magelang.",true))
		elif id=="exit" and mission>=3: _finish_chapter()
		else: _notify("Dengarkan kabar tetua dan keluarga warga dahulu.")
	elif id=="guide":
		_start_dialogue(story.guide,func() -> void:
			mission = maxi(mission,1)
			facts_unlocked = 1
			GameState.set_objective("Temui Sari dekat pos utama."))
	elif id=="commander" and mission>=1:
		_start_dialogue(story.challenge,func() -> void:
			mission = 2
			facts_unlocked = 2
			if not GameState.night_boss_defeated.get("commander",false): _enter_commander.call_deferred())
	else: _notify("Temui penunjuk jalan lebih dahulu.")

func _enter_commander() -> void:
	GameState.hold_encounter_origin(self)
	GameState.boss_trial_kind = "commander"
	var tree := get_tree()
	tree.current_scene = null
	get_parent().remove_child(self)
	var arena: Node = load("res://boss_trial.tscn").instantiate()
	tree.root.add_child(arena)
	tree.current_scene = arena

func _finish_chapter() -> void:
	GameState.complete_chapter(4,self)
	stage = Stage.COMPLETE
	player.controls_enabled = false
	GameState.ending_started = true
	var box := _new_overlay("result","BAB 4 SELESAI","Kabar warga telah disampaikan. Jalan berikutnya menuju Magelang.")
	_button(box,"Lanjut ke Bab 5 • Magelang",Rect2(40,250,780,58),func() -> void: GameState.travel_to(5,self,false),true)
	_button(box,"Menu utama",Rect2(40,340,780,58),_return_menu)

func _ending_choice() -> void:
	stage = Stage.COMPLETE
	player.controls_enabled = false
	GameState.ending_started = true
	GameState.complete_chapter(5,self)
	var count := 0
	for boss_kind in ["buto","banaspati","headless"]:
		if GameState.night_boss_defeated.get(boss_kind,false): count += 1
	var box := _new_overlay("ending_choice","Langkah terakhir","Komandan dikalahkan. Tiga legenda malam: %d/3. Pilihanmu menentukan nasib Jaka, Sari, dan warga." % count)
	_button(box,"Antar warga pulang",Rect2(40,205,780,62),func() -> void: _show_ending("pulang"),true)
	_button(box,"Bertahan sendiri agar mereka lolos",Rect2(40,285,780,62),func() -> void: _show_ending("bertahan"))
	var secret := _button(box,"Bawa warga dan catatan bersama" if GameState.secret_ending_ready() else "Penutup rahasia • kalahkan semua urban boss (%d/3)" % count,Rect2(40,365,780,62),func() -> void: _show_ending("jejak"))
	secret.disabled = not GameState.secret_ending_ready()
	_paragraph(box,"Penangkapan Diponegoro tetap menjadi bagian sejarah. Yang berubah adalah jejak orang-orang yang kamu lindungi.",Rect2(40,458,780,70),18,MUTED)
	_button(box,"Lengkapi legenda melalui peta [M]",Rect2(40,527,780,36),func() -> void: journey.show_map()).add_theme_font_size_override("font_size",16)

func _show_ending(id: String) -> void:
	if id=="jejak" and not GameState.secret_ending_ready(): return
	var ending: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/endings.json"))[id]
	GameState.unlocked_endings[id] = true
	GameState.request_save()
	var box := _new_overlay("ending",str(ending.title),str(ending.requirement))
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40,175)
	scroll.size = Vector2(780,300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var full_text := RichTextLabel.new()
	full_text.text = str(ending.text)
	full_text.custom_minimum_size.x = 755
	full_text.fit_content = true
	full_text.scroll_active = false
	full_text.add_theme_font_size_override("normal_font_size",18)
	full_text.add_theme_color_override("default_color",PAPER)
	scroll.add_child(full_text)
	_button(box,"Menu utama",Rect2(40,490,380,58),_return_menu,true)
	_button(box,"Ulangi Magelang",Rect2(440,490,380,58),_restart)
	if is_instance_valid(ending_director): ending_director.queue_free()
	ending_director = preload("res://scripts/ending_director.gd").new()
	ending_director.chapter = self
	ending_director.ending = ending
	ending_director.ending_id = id
	add_child(ending_director)

func _show_line() -> void:
	super._show_line()
	var name: String = lines[line_index].speaker
	var file := "sesepuh.png" if name=="Tetua desa" else ("NPC Ibu2.png" if name=="Warga" else ("NPC cwo.png" if name=="Penunjuk jalan" else ""))
	if file.is_empty(): return
	var image := AtlasTexture.new()
	image.atlas = load("res://assets/Karakter/"+file)
	var bounds: Rect2 = ActorVisual.REGIONS[file]
	bounds.size.y *= 0.48
	image.region = bounds
	portrait.texture = image

func _on_player_died() -> void:
	stage = Stage.FAILED
	player.controls_enabled = false
	var box := _new_overlay("result","Perjalanan belum berakhir","Kembali dari gubuk. Poin dan upgrade tetap tersimpan selama sesi ini.")
	_button(box,"Kembali ke gubuk",Rect2(40,350,780,58),func() -> void:
		_close_overlay()
		stage = Stage.EXPLORE
		GameState.ending_started = false
		player.reset_health()
		player.position = checkpoint,true)
	_button(box,"Menu utama",Rect2(40,440,780,58),_return_menu)

func _restart() -> void:
	if chapter_number==5: GameState.night_boss_defeated.erase("commander")
	get_tree().paused = false
	get_tree().reload_current_scene()

extends "res://scripts/chapter_one.gd"
## Five connected segments reusing Chapter 1 actors, dialogue, UI and state.
const LENGTH := 15100.0
const RAVINE_START := 11900.0
const RAVINE_END := 13730.0
const GUIDE_X := 14350.0
const PATROL_POSITIONS := [7400, 7660, 7910, 8190, 8400, 8600, 8800, 9090, 9340, 9510, 9730, 9950, 10250, 10550, 10800, 11360]
const Soldier = preload("res://scripts/enemy.gd")
var mission: int = 0
var markers: Array[Dictionary] = []
var platforms: Array[Rect2] = []
var checkpoint := Vector2(230,570)
var checkpoint_name := "Tepi desa"
var checkpoint_reached: bool = false
var ravine_checkpoint_reached := false
var carried_supply: bool = false
var delivered: bool = false
var crossed: bool = false
var patrol_started: bool = false
var defeated_count: int = 0
var soldiers: Array[Node] = []
var motes: Array[Vector2] = []
var location_label: Label
var combat_label: Label
var nearest: int = -1

func _ready() -> void:
	super._ready()
	story = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_two.json"))
	start_chapter()

func _set_menu() -> void:
	menu.hide()
	hud.show()
	player.controls_enabled = false

func _build_world() -> void:
	var backdrop := CanvasLayer.new()
	backdrop.layer = -10
	add_child(backdrop)
	var sky := TextureRect.new()
	sky.texture = load("res://assets/Background/Forest/forest_sky.png")
	sky.size = Vector2(1280,720)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.add_child(sky)
	world = Node2D.new()
	world.z_index = -1
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	mountains = Node2D.new()
	world.add_child(mountains)
	for i in range(-1,11):
		_region_sprite(mountains,"res://assets/Background/Forest/forest_distant_trees.png",Rect2(0,0,2172,724),Vector2(i*1737,0),Vector2(0.8,0.8))
	# Overlap the two panoramas so the village gives way to the forest gradually.
	for i in range(9):
		var forest := _region_sprite(world,"res://assets/Background/Forest/forest_midground.png.png",Rect2(0,0,2172,724),Vector2(850 + i * 1737,26),Vector2(0.8,0.8))
		if i == 0:
			forest.material = _horizontal_fade(0.0, 0.23, false)
	var village := _region_sprite(world,"res://assets/Background/Tegalrejo/tegalrejo_village.png",Rect2(0,265,2172,355),Vector2(0,290),Vector2(0.8,0.8))
	village.material = _horizontal_fade(0.60, 1.0, true)
	_region_sprite(world,"res://assets/Background/Selarong/Pixel Art Karst Cliff Panorama.png",Rect2(0,0,2172,724),Vector2(13400,63),Vector2(0.9,0.7))
	var cliff: Sprite2D = world.get_child(world.get_child_count()-1)
	var edge_material := ShaderMaterial.new()
	var edge_shader := Shader.new()
	edge_shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); c.a*=smoothstep(0.0,0.12,UV.x); COLOR=c; }"
	edge_material.shader = edge_shader
	cliff.material = edge_material
	_floor(0,2500)
	_floor(3200,RAVINE_START-3200)
	_floor(RAVINE_END,LENGTH-RAVINE_END)
	# An easy alternate crossing: rises stay below Jaka's 90-pixel jump apex.
	_platform(Rect2(2550,525,180,35))
	_platform(Rect2(2770,475,180,35))
	_platform(Rect2(2990,525,180,35))
	# Optional lookout and the supply ledge.
	_platform(Rect2(1040,510,180,28))
	_platform(Rect2(1240,455,330,28))
	_platform(Rect2(4870,510,180,28))
	_platform(Rect2(5080,450,260,28))
	# Two elevated bypasses above the first six patrol positions.
	for base_x in [6940.0,8100.0]:
		_platform(Rect2(base_x,510,170,28))
		_platform(Rect2(base_x+190,450,170,28))
		_platform(Rect2(base_x+380,400,570,28))
		_platform(Rect2(base_x+970,455,170,28))
	# The last crossing alternates climbs, drops, and shorter landing areas.
	for ledge in [
		Rect2(11960, 520, 150, 25), Rect2(12200, 465, 160, 25),
		Rect2(12450, 415, 170, 25), Rect2(12720, 462, 125, 25),
		Rect2(12935, 403, 160, 25), Rect2(13190, 454, 170, 25),
		Rect2(13450, 507, 175, 25),
	]:
		_platform(ledge)
	_solid(Vector2(-30,360),Vector2(60,900))
	_solid(Vector2(LENGTH+30,360),Vector2(60,900))
	_add_walker("female", 1050.0, 960.0, 1160.0)
	player = preload("res://player.tscn").instantiate()
	player.world_right = LENGTH-40
	player.position = Vector2(230,570)
	world.add_child(player)
	cat = _make_cat(Vector2(155.0, FLOOR_Y - 56.0))
	camera = Camera2D.new()
	camera.position = Vector2(640,CAMERA_Y)
	camera.zoom = Vector2.ONE * CAMERA_ZOOM
	camera.limit_left = 0
	camera.limit_right = int(LENGTH)
	camera.limit_top = 0
	camera.limit_bottom = 800
	world.add_child(camera)
	_npc("Sari", SARI_IMAGE, SARI_REGION, 720)
	_npc("Warga", "res://assets/Karakter/NPC cwo.png",Rect2(253,150,483,1330),1650)
	_npc("Lasmi", "res://assets/Karakter/NPC Ibu2.png",Rect2(254,152,463,1314),4480)
	_npc("Warga penerima", "res://assets/Karakter/sesepuh.png",Rect2(264,102,499,1377),5940)
	_npc("Utusan", "res://assets/Karakter/NPC cwo.png",Rect2(253,150,483,1330),GUIDE_X)
	_marker("sari","Bicara dengan Sari",Vector2(720,520))
	_marker("villager","Tanya keadaan jalan",Vector2(1650,520))
	_marker("note","Baca catatan perjalanan",Vector2(1400,410))
	_marker("bridge","Periksa jembatan rusak",Vector2(2370,520))
	_marker("lasmi","Bicara dengan Lasmi",Vector2(4480,520))
	_marker("supply","Ambil bekal",Vector2(5200,410))
	_marker("deliver","Antarkan bekal",Vector2(5940,520))
	_marker("guide","Bicara dengan utusan",Vector2(GUIDE_X,520))
	for i in range(35):
		motes.append(Vector2(fmod(i*359.0,LENGTH),240+fmod(i*47.0,270)))
	_world_label("TEPI DESA",Vector2(130,390),24,GOLD)
	_world_label("JEMBATAN RUSAK  /  JALUR BATU DI ATAS",Vector2(2070,350),18,GOLD)
	_world_label("TEMPAT SINGGAH",Vector2(4230,360),22,GOLD)
	_world_label("CHECKPOINT  /  WASPADA PATROLI",Vector2(6520,350),19,GOLD)
	_world_label("JURANG  /  IKUTI PIJAKAN BATU",Vector2(11580,365),20,GOLD)
	_world_label("MENUJU SELARONG",Vector2(14050,350),24,GOLD)
	_add_upgrade_hut(6190.0)

func _floor(x: float, width: float) -> void:
	_solid(Vector2(x+width/2,670),Vector2(width,200))
	var ground_path := "res://assets/Background/Tegalrejo/ground.png" if x < 3200 else "res://assets/Background/Forest/forest_ground.png.png"
	var cursor := x
	while cursor < x+width:
		var w := minf(1303.2,x+width-cursor)
		_region_sprite(world,ground_path,Rect2(0,346,w/0.6,378),Vector2(cursor,564),Vector2(0.6,0.6))
		cursor += w

func _platform(rect: Rect2) -> void:
	platforms.append(rect)
	_solid(rect.get_center(),rect.size)
	var body: StaticBody2D = world.get_child(world.get_child_count()-1)
	var collider: CollisionShape2D = body.get_child(0)
	collider.one_way_collision = true

func _marker(id: String, caption: String, at: Vector2) -> void:
	markers.append({"id":id,"caption":caption,"at":at})

func _build_ui() -> void:
	super._build_ui()
	_relabel(ui,"01  /  TEGALREJO","02  /  JALUR PERLAWANAN")
	chapter_steps.text = "1825"
	location_label = _label(hud,"",Rect2(32,139,750,28),18,GOLD)
	combat_label = _label(hud,"",Rect2(30,178,920,28),18,PAPER)
	menu.hide()

func _relabel(node: Node, old_text: String, new_text: String) -> void:
	if (node is Label or node is RichTextLabel or node is Button) and node.text == old_text:
		node.text = new_text
	for child in node.get_children():
		_relabel(child,old_text,new_text)

func start_chapter() -> void:
	menu.hide()
	hud.show()
	stage = Stage.INTRO
	player.controls_enabled = false
	GameState.set_objective("Temui Sari di tepi desa.")
	if not story.has("sari"):
		return
	_start_dialogue(story.intro,func() -> void:
		stage = Stage.EXPLORE
		player.controls_enabled = true)

func _process(delta: float) -> void:
	if not is_instance_valid(player) or paused:
		return
	elapsed += delta
	if GameState.dialogue_active:
		typing += delta*48
		dialogue_label.visible_characters = int(typing)
	camera.position.x = lerpf(camera.position.x,clampf(player.position.x+150,CAMERA_HALF_WIDTH,LENGTH-CAMERA_HALF_WIDTH),1-exp(-delta*5))
	mountains.position.x = (camera.position.x-CAMERA_HALF_WIDTH)*0.3
	var cat_target := Vector2(player.position.x-player.facing*70, player.position.y-56.0)
	var cat_moving := cat.position.distance_to(cat_target) > 12.0
	cat.position = cat.position.lerp(cat_target,1-exp(-delta*4))
	cat.flip_h = player.facing < 0
	_update_cat_animation(cat_moving, not player.is_on_floor())
	var x := player.position.x
	var region := "A / Tepi desa"
	if x>1900: region = "B / Penyeberangan rusak"
	if x>4000: region = "C / Suara di hutan"
	if x>6500: region = "D / Jalur patroli"
	if x>11500: region = "E / Jalur tebing menuju Selarong"
	location_label.text = region
	location_label.visible = not GameState.dialogue_active
	combat_label.visible = not GameState.dialogue_active
	var parry_status := "%.1f dtk" % player.parry_cooldown if player.parry_cooldown > 0.0 else "siap"
	combat_label.text = "K Parry: %s   •   H Heal: %d   •   L Ulti: %d/%d" % [parry_status, GameState.heal_stock, player.ultimate_charge, player.ULTIMATE_HITS]
	nearest = -1
	var best := 130.0
	for i in range(markers.size()):
		var distance: float = Vector2(x,player.position.y-50).distance_to(markers[i].at)
		if distance < best:
			nearest = i
			best = distance
	prompt.text = "[ E ]  "+str(markers[nearest].caption) if nearest>=0 and not GameState.dialogue_active else ""
	if not GameState.dialogue_active and stage==Stage.EXPLORE:
		if player.position.y>830:
			_respawn()
			return
		if x>3250 and mission==1:
			crossed = true
			mission = 2
			checkpoint = Vector2(3370,570)
			checkpoint_name = "Seberang jembatan"
			GameState.set_objective("Cari warga yang membutuhkan bantuan di hutan.")
		if x>6500 and mission>=4 and not checkpoint_reached:
			checkpoint_reached = true
			checkpoint = Vector2(6580,570)
			checkpoint_name = "Sebelum patroli"
			player.reset_health()
			_spawn_patrol()
			_notify("Checkpoint tersimpan. Jalur atas melewati sebagian patroli; J untuk melawan.")
		if x>11700 and mission==4:
			mission = 5
			ravine_checkpoint_reached = true
			checkpoint = Vector2(11740, FLOOR_Y)
			checkpoint_name = "Sebelum jurang"
			GameState.set_objective("Seberangi jurang untuk menemui utusan.")
			_notify("Checkpoint tersimpan. Lompat dari tepi pijakan untuk mencapai sisi lain.")
		if x>LENGTH-300 and mission==6:
			_finish_chapter()
	# Gates are quest-based, not defeat counters: stealth remains a valid route.
	if mission==0 and x>2410: player.position.x = 2410
	if mission<4 and x>6480: player.position.x = 6480
	if mission<6 and x>LENGTH-400: player.position.x = LENGTH-400
	if notice_time>0:
		notice_time -= delta
		notice.visible = notice_time>0
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and not GameState.dialogue_active and not paused and not overlay.visible:
		if nearest>=0:
			_interact(str(markers[nearest].id))
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func _interact(id: String) -> void:
	if id=="sari":
		_start_dialogue(story.sari,func() -> void:
			if mission==0:
				mission=1
				facts_unlocked=1
				GameState.set_objective("Cari jalur alternatif di jembatan yang rusak."))
	elif id=="note" or id=="villager" or id=="bridge":
		_start_dialogue(story[id],func() -> void: pass)
	elif id=="lasmi":
		_start_dialogue(story.lasmi,func() -> void:
			if mission==2:
				mission=3
				GameState.set_objective("Ambil bekal di pondok atas, lalu antarkan kepada warga."))
	elif id=="supply":
		if mission==3 and not carried_supply:
			carried_supply=true
			GameState.set_objective("Bekal dibawa. Antarkan kepada warga di kanan.")
			if GameState.claim_aid_heal():
				_notify("Bekal diambil dan kamu mendapat 1 heal. Antarkan bekal ke warga.")
			else:
				_notify("Bekal diambil. Antarkan bekal ke warga.")
		else:
			_notify("Temui Lasmi dahulu; bekal hanya perlu diambil satu kali.")
	elif id=="deliver":
		if mission==3 and carried_supply:
			_start_dialogue(story.delivery,func() -> void:
				delivered=true
				carried_supply=false
				mission=4
				facts_unlocked=2
				GameState.set_objective("Lewati jalur patroli. Gunakan jalur atas atau hadapi tentara."))
		else:
			_notify("Warga menunggu bekal dari Lasmi.")
	elif id=="guide":
		if mission>=5:
			_start_dialogue(story.guide,func() -> void:
				mission=6
				facts_unlocked=3
				GameState.set_objective("Ikuti jalur kanan menuju Selarong.",true))

func _spawn_patrol() -> void:
	patrol_started = true
	for shot in get_tree().get_nodes_in_group("patrol_shots"):
		shot.queue_free()
	for old in soldiers:
		if is_instance_valid(old): old.queue_free()
	soldiers.clear()
	defeated_count = 0
	for i in range(PATROL_POSITIONS.size()):
		var enemy := CharacterBody2D.new()
		enemy.set_script(Soldier)
		enemy.position=Vector2(PATROL_POSITIONS[i],570)
		enemy.world_right=LENGTH-40
		enemy.target=player
		enemy.chase_speed=105.0+float(i%3)*7
		enemy.warning_time=0.55
		enemy.recovery_time=1.15
		enemy.defeated.connect(_on_soldier_defeated)
		world.add_child(enemy)
		soldiers.append(enemy)

func _on_soldier_defeated(_enemy: Node) -> void:
	defeated_count += 1
	if GameState.award_patrol_defeat():
		_notify("Tujuh tentara dikalahkan. Kamu mendapat 1 heal.")

func _on_player_died() -> void:
	stage=Stage.FAILED
	player.controls_enabled=false
	GameState.ending_started=true
	var box := _new_overlay("result","Coba lagi dari checkpoint",checkpoint_name+". Misi bantuanmu tetap tersimpan.")
	_paragraph(box,"Tentara memberi tanda sebelum menyerang. Mundur, lompat, atau gunakan jalur atas untuk melewati mereka.",Rect2(40,190,780,160),24)
	_button(box,"Lanjut dari checkpoint",Rect2(40,420,780,58),_respawn,true)
	_button(box,"Menu utama",Rect2(40,495,780,50),_return_menu)

func _respawn() -> void:
	_close_overlay()
	GameState.dialogue_active=false
	GameState.ending_started=false
	stage=Stage.EXPLORE
	player.position=checkpoint
	player.reset_health()
	player.invulnerable_time=2
	for shot in get_tree().get_nodes_in_group("patrol_shots"):
		shot.queue_free()
	if ravine_checkpoint_reached:
		mission = 5
		GameState.set_objective("Seberangi jurang untuk menemui utusan.")
	elif checkpoint_reached:
		mission=4
		_spawn_patrol()
		GameState.set_objective("Lewati jalur patroli. Gunakan jalur atas atau hadapi tentara.")
	camera.position.x=clampf(checkpoint.x+150,CAMERA_HALF_WIDTH,LENGTH-CAMERA_HALF_WIDTH)
	_notify("Kembali ke checkpoint: "+checkpoint_name)

func _finish_chapter() -> void:
	stage=Stage.TRANSITION
	player.controls_enabled=false
	GameState.ending_started=true
	_start_dialogue(story.outro,func() -> void:
		var tween := create_tween()
		tween.tween_property(fade,"color:a",1.0,0.6)
		tween.tween_callback(_chapter_three_card))

func _chapter_three_card() -> void:
	fade.color.a=0
	stage=Stage.COMPLETE
	hud.hide()
	var box := _new_overlay("result","BAB 2 SELESAI","Bab berikutnya: Selarong, tempat perjuangan")
	_paragraph(box,"Di balik pepohonan, tebing Selarong mulai terlihat. Seorang penjaga menunggu di mulut gua. Pesan apa yang harus Jaka bawa selanjutnya?",Rect2(40,190,780,150),24)
	_label(box,"Bekal tersampaikan  •  %d / %d patroli dikalahkan" % [defeated_count, PATROL_POSITIONS.size()],Rect2(40,360,780,40),21,GOLD)
	_label(box,"Penjaga Selarong menunggu pesanmu di dekat gua.",Rect2(40,414,780,35),19,MUTED)
	_button(box,"Lanjut Bab 3",Rect2(40,494,380,58),func() -> void: get_tree().change_scene_to_file("res://bab_selarong.tscn"),true)
	_button(box,"Menu utama",Rect2(440,494,380,58),_return_menu)

func _show_pause() -> void:
	super._show_pause()
	_relabel(overlay,"Ulangi Bab 1","Ulangi Bab 2")
	_relabel(overlay,"Ambil waktu sejenak. Perjalananmu di Tegalrejo menunggu.","Ambil waktu sejenak. Jalur menuju Selarong menunggu.")

func _show_journal() -> void:
	super._show_journal()
	_relabel(overlay,"Fakta yang kamu temukan di Tegalrejo. Dialog dan pertarungan Jaka adalah dramatisasi fiksi.","Catatan dari perjalanan menuju Selarong. Jaka, warga, dan misi bantuan adalah dramatisasi fiksi.")

func _show_line() -> void:
	super._show_line()
	var speaker: String = lines[line_index].speaker
	var atlas := AtlasTexture.new()
	if speaker == "Lasmi":
		atlas.atlas = load("res://assets/Karakter/NPC Ibu2.png")
		atlas.region = Rect2(254,152,463,631)
	elif speaker == "Warga":
		atlas.atlas = load("res://assets/Karakter/NPC cwo.png")
		atlas.region = Rect2(253,150,483,638)
	else:
		return
	portrait.texture = atlas

func _return_menu() -> void:
	get_tree().paused=false
	GameState.start_on_load=false
	get_tree().change_scene_to_file("res://bab_tegalrejo.tscn")

func _draw() -> void:
	# Simple code-drawn scenery placeholders use the existing earth palette.
	draw_rect(Rect2(2500,579,700,156),Color("365c5a"))
	draw_rect(Rect2(RAVINE_START, 605, RAVINE_END - RAVINE_START, 130), Color("344d49"))
	for i in range(9):
		var wave_x := 2520.0+float(i)*76.0+sin(elapsed)*8.0
		draw_line(Vector2(wave_x,655+i%3*16),Vector2(wave_x+38,655+i%3*16),Color("8dada0"),2)
	for rect in platforms:
		if (rect.position.x>2500 and rect.position.x<3200) or (rect.position.x>RAVINE_START and rect.position.x<RAVINE_END):
			draw_colored_polygon(PackedVector2Array([rect.position+Vector2(14,7),Vector2(rect.end.x-12,rect.position.y+7),Vector2(rect.end.x+17,735),Vector2(rect.position.x-14,735)]),Color("555c4b"))
			draw_line(rect.position+Vector2(25,35),Vector2(rect.position.x+13,720),Color("727865"),9)
		else:
			for post_x in [rect.position.x+17,rect.end.x-17]:
				draw_line(Vector2(post_x,rect.end.y),Vector2(post_x,570),Color("66513b"),8)
		draw_rect(rect,Color("65513a"))
		draw_rect(Rect2(rect.position,Vector2(rect.size.x,7)),Color("a69b5a"))
		for x in range(int(rect.position.x)+12,int(rect.end.x),32):
			draw_line(Vector2(x,rect.position.y+8),Vector2(x,rect.end.y),Color("453724"),2)
	# Lookout noticeboard and supply shelter make the optional upper paths legible.
	draw_rect(Rect2(1375,409,50,30),Color("dfcc96"))
	for y in [417,425,433]:
		draw_line(Vector2(1382,y),Vector2(1418,y),Color("756346"),2)
	for x in [5095,5325]:
		draw_line(Vector2(x,345),Vector2(x,450),Color("70543a"),7)
	draw_colored_polygon(PackedVector2Array([Vector2(5060,347),Vector2(5210,303),Vector2(5360,347)]),Color("877044"))
	# Broken deck and clear route markers.
	for x in [2470,2500,3180,3210]:
		draw_line(Vector2(x,570),Vector2(x+18,620),Color("806144"),11)
	for x in [2540,2780,3000]:
		draw_colored_polygon(PackedVector2Array([Vector2(x,430),Vector2(x+22,438),Vector2(x,446)]),GOLD)
	if not carried_supply and not delivered:
		draw_rect(Rect2(5175,419,50,31),Color("a87f45"))
		draw_line(Vector2(5200,419),Vector2(5200,450),Color("ded098"),5)
	for mote in motes:
		draw_circle(mote+Vector2(sin(elapsed+mote.x)*8,sin(elapsed*0.7+mote.x)*6),1.5,Color(0.85,0.92,0.55,0.35))

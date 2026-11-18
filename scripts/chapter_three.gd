extends "res://scripts/chapter_one.gd"
## Selarong: a short exploration chapter connecting the forest to the affected villages.
const LENGTH := 5000.0
const GUARD_X := 2140.0
const PRINCE_X := 3540.0
const LOOKOUT_X := 4440.0
var mission := 0
var nearest := -1
var checkpoint := Vector2(1120.0, FLOOR_Y)
var markers: Array[Dictionary] = []
var location_label: Label
var action_label: Label

func _ready() -> void:
	# The parent builds shared actors and UI; this chapter supplies its own story.
	GameState.start_on_load = false
	super._ready()
	story = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_three.json"))
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
	sky.texture = load("res://assets/Background/Selarong/sky.png")
	sky.size = Vector2(1280, 720)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.add_child(sky)
	world = Node2D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	mountains = Node2D.new()
	world.add_child(mountains)
	for i in range(-1, 5):
		var cliff := _region_sprite(mountains,"res://assets/Background/Selarong/Pixel Art Karst Cliff Panorama.png",Rect2(0,0,2172,724),Vector2(i*1737,52),Vector2(0.8,0.72))
		cliff.flip_h = posmod(i,2)==1
	# The cave sits behind the characters. The supplied transparent artwork meets the ground.
	_region_sprite(world,"res://assets/Background/Selarong/Pixel-Art Limestone Cave Entrance.png",Rect2(0,0,1774,887),Vector2(3020,37),Vector2(0.6,0.6))
	_ground(0,1300)
	_ground(1740,LENGTH-1740)
	for ledge in [Rect2(1305,525,125,28),Rect2(1480,465,145,28),Rect2(1675,520,105,28)]:
		_platform(ledge)
	_platform(Rect2(4380,510,160,60))
	_solid(Vector2(-30,360),Vector2(60,900))
	_solid(Vector2(LENGTH+30,360),Vector2(60,900))
	player = preload("res://player.tscn").instantiate()
	player.world_right = LENGTH-40
	player.position = Vector2(220,FLOOR_Y)
	world.add_child(player)
	cat = _make_cat(Vector2(150,FLOOR_Y-56))
	camera = Camera2D.new()
	camera.position = Vector2(CAMERA_HALF_WIDTH,CAMERA_Y)
	camera.zoom = Vector2.ONE*CAMERA_ZOOM
	camera.limit_left = 0
	camera.limit_right = int(LENGTH)
	camera.limit_top = 0
	camera.limit_bottom = 800
	world.add_child(camera)
	_npc("Penjaga","res://assets/Karakter/Penjaga Selarong.png",Rect2(0,0,1024,1536),GUARD_X)
	_npc("Diponegoro","res://assets/Karakter/Pangeran Diponegoro.png",Rect2(265,33,517,1468),PRINCE_X)
	markers.append({"id":"guard","caption":"Bicara dengan penjaga","at":Vector2(GUARD_X,520)})
	markers.append({"id":"prince","caption":"Bicara dengan Diponegoro","at":Vector2(PRINCE_X,520)})
	markers.append({"id":"lookout","caption":"Amati jalur desa","at":Vector2(LOOKOUT_X,460)})
	_world_label("LERENG SELARONG",Vector2(140,345),24,GOLD)
	_world_label("IKUTI PIJAKAN BATU",Vector2(1100,355),19,GOLD)
	_world_label("GUA SELARONG",Vector2(3270,325),24,GOLD)
	_world_label("BATU PENGAMAT",Vector2(4280,360),20,GOLD)
	_add_upgrade_hut(2780)

func _ground(x: float, width: float) -> void:
	_solid(Vector2(x+width/2,670),Vector2(width,200))
	var cursor := x
	while cursor < x+width:
		var piece := minf(1303.2,x+width-cursor)
		_region_sprite(world,"res://assets/Background/Selarong/Panoramic Pixel-Art Grassland Ground Tile.png",Rect2(0,346,piece/0.6,378),Vector2(cursor,564),Vector2(0.6,0.6))
		cursor += piece

func _platform(rect: Rect2) -> void:
	_solid(rect.get_center(),rect.size)
	var body: StaticBody2D = world.get_child(world.get_child_count()-1)
	var collision: CollisionShape2D = body.get_child(0)
	collision.one_way_collision = true
	var stone := Polygon2D.new()
	stone.color = Color("78745d")
	stone.polygon = PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	world.add_child(stone)

func _build_ui() -> void:
	super._build_ui()
	_relabel(ui,"01  /  TEGALREJO","03  /  SELARONG")
	chapter_steps.text = "1825"
	location_label = _label(hud,"",Rect2(32,139,680,29),18,GOLD)
	action_label = _label(hud,"",Rect2(32,176,900,29),18,PAPER)
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
	GameState.set_objective("Temui penjaga di kawasan gua Selarong.")
	_start_dialogue(story.intro,func() -> void:
		stage = Stage.EXPLORE
		player.controls_enabled = true
		_notify("Seberangi lereng batu untuk menemui penjaga."))

func _process(delta: float) -> void:
	if paused:
		return
	elapsed += delta
	if GameState.dialogue_active:
		typing += delta*48
		dialogue_label.visible_characters = int(typing)
	camera.position.x = lerpf(camera.position.x,clampf(player.position.x+150,CAMERA_HALF_WIDTH,LENGTH-CAMERA_HALF_WIDTH),1-exp(-delta*5))
	mountains.position.x = (camera.position.x-CAMERA_HALF_WIDTH)*0.23
	var cat_target := Vector2(player.position.x-player.facing*70,player.position.y-56)
	var cat_moving := cat.position.distance_to(cat_target)>12
	cat.position = cat.position.lerp(cat_target,1-exp(-delta*4))
	cat.flip_h = player.facing<0
	_update_cat_animation(cat_moving,not player.is_on_floor())
	location_label.text = "A / Lereng" if player.position.x<1800 else ("B / Penjaga gua" if player.position.x<2950 else "C / Gua Selarong")
	location_label.visible = not GameState.dialogue_active
	action_label.text = "K Parry  •  H Heal: %d  •  L Ulti: %d/%d" % [GameState.heal_stock,player.ultimate_charge,player.ULTIMATE_HITS]
	action_label.visible = not GameState.dialogue_active
	nearest = -1
	if stage==Stage.EXPLORE and not GameState.dialogue_active:
		var best := 130.0
		for i in range(markers.size()):
			var distance: float = Vector2(player.position.x,player.position.y-50).distance_to(markers[i].at)
			if distance<best:
				best=distance
				nearest=i
	prompt.text = "[ E ]  "+str(markers[nearest].caption) if nearest>=0 else ""
	if stage==Stage.EXPLORE and not GameState.dialogue_active and player.position.y>830:
		_respawn()
	if player.position.x>1200 and mission==0:
		checkpoint=Vector2(1120,FLOOR_Y)
	if player.position.x>1900 and mission>=1:
		checkpoint=Vector2(1900,FLOOR_Y)
	if notice_time>0:
		notice_time-=delta
		notice.visible=notice_time>0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("interact"):
		if not paused and not overlay.visible:
			if GameState.dialogue_active:
				advance_dialogue()
			elif stage==Stage.EXPLORE and nearest>=0:
				_interact(str(markers[nearest].id))
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func _interact(id: String) -> void:
	if id=="guard":
		_start_dialogue(story.guard,func() -> void:
			if mission==0:
				mission=1
				facts_unlocked=1
				GameState.set_objective("Temui Diponegoro di kawasan gua."))
	elif id=="prince":
		if mission==0:
			_notify("Penjaga gua perlu mendengar pesanmu dahulu.")
		elif mission==1:
			_start_dialogue(story.prince,func() -> void:
				mission=2
				facts_unlocked=2
				GameState.set_objective("Amati jalur desa dari batu di kanan."))
		elif mission==3:
			mission=4
			_start_dialogue(story.report,func() -> void:
				facts_unlocked=3
				_finish_chapter())
		else:
			_notify("Amati jalur di kanan, lalu kembali ke sini.")
	elif id=="lookout":
		if mission==2:
			_start_dialogue(story.lookout,func() -> void:
				mission=3
				GameState.set_objective("Kembali ke Diponegoro dan laporkan pengamatanmu."))
		else:
			_notify("Temui Diponegoro dahulu sebelum memeriksa jalur ini.")

func _respawn() -> void:
	player.position=checkpoint
	player.velocity=Vector2.ZERO
	player.invulnerable_time=2
	_notify("Kembali ke tepi lereng.")

func _on_player_died() -> void:
	stage=Stage.FAILED
	player.controls_enabled=false
	var box := _new_overlay("result","Perjalanan belum berakhir","Coba lagi dari lereng Selarong.")
	_button(box,"Kembali ke checkpoint",Rect2(40,420,780,58),func() -> void:
		_close_overlay()
		GameState.ending_started=false
		stage=Stage.EXPLORE
		player.reset_health()
		player.controls_enabled=true
		_respawn(),true)
	_button(box,"Menu utama",Rect2(40,495,780,50),_return_menu)

func _finish_chapter() -> void:
	stage=Stage.COMPLETE
	player.controls_enabled=false
	GameState.ending_started=true
	GameState.set_objective("Kabar warga telah disampaikan di Selarong.",true)
	hud.hide()
	var box := _new_overlay("result","BAB 3 SELESAI","Selarong • perjalanan berlanjut ke desa terdampak")
	_paragraph(box,"Jaka telah menyampaikan kabar warga dan mengamati jalur berikutnya. Bab 4: Desa Terdampak akan dibuat pada tahap selanjutnya.",Rect2(40,190,780,160),24)
	_label(box,"3 catatan sejarah dapat dibaca dari jurnal selama bab ini.",Rect2(40,390,780,45),20,GOLD)
	_button(box,"Main lagi",Rect2(40,494,380,58),_restart,true)
	_button(box,"Menu utama",Rect2(440,494,380,58),_return_menu)

func _show_line() -> void:
	super._show_line()
	if str(lines[line_index].speaker)=="Pangeran Diponegoro":
		var atlas := AtlasTexture.new()
		atlas.atlas=load("res://assets/Karakter/Pangeran Diponegoro.png")
		atlas.region=Rect2(265,33,517,705)
		portrait.texture=atlas

func _show_pause() -> void:
	super._show_pause()
	_relabel(overlay,"Ulangi Bab 1","Ulangi Bab 3")
	_relabel(overlay,"Ambil waktu sejenak. Perjalananmu di Tegalrejo menunggu.","Ambil waktu sejenak. Selarong menunggu.")

func _show_journal() -> void:
	super._show_journal()
	_relabel(overlay,"Fakta yang kamu temukan di Tegalrejo. Dialog dan pertarungan Jaka adalah dramatisasi fiksi.","Catatan dari Selarong. Jalur dan percakapan Jaka adalah dramatisasi fiksi.")

func _return_menu() -> void:
	get_tree().paused=false
	GameState.start_on_load=false
	get_tree().change_scene_to_file("res://bab_tegalrejo.tscn")

extends Node
## Shared persistence and map UI; combat arenas save the held story scene.
var chapter: Node
var autosave_time := 0.0
var last_signature := ""
var map_layer: CanvasLayer
var map_root: Control
var was_paused := false
var was_tree_paused := false
var saved_hint: Label
var hint_time := 0.0

class LockIcon extends Control:
	func _draw() -> void:
		draw_arc(Vector2(15,13),8,PI,TAU,12,Color("c5ad82"),3)
		draw_style_box(_box(),Rect2(3,12,24,20))
		draw_line(Vector2(15,19),Vector2(15,26),Color("243933"),3)
	func _box() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("c5ad82")
		style.set_corner_radius_all(3)
		return style

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	saved_hint = chapter._label(chapter.hud,"",Rect2(30,250,500,24),14,chapter.MUTED)
	chapter._button(chapter.hud,"Peta [M]",Rect2(1110,666,140,32),show_map).add_theme_font_size_override("font_size",14)
	GameState.save_completed.connect(_saved)
	_begin.call_deferred()

func _begin() -> void:
	if GameState.chapter_id(chapter)==0: return
	if GameState.pending_restore==GameState.chapter_id(chapter): GameState.restore_chapter(chapter)
	elif chapter.stage!=chapter.Stage.MENU: GameState.begin_chapter(chapter)

func _saved(success: bool) -> void:
	saved_hint.text = "Tersimpan" if success else "Belum bisa menyimpan. Coba lagi dari peta."
	if success and OS.has_feature("web") and not OS.is_userfs_persistent(): saved_hint.text = "Tersimpan untuk sesi ini. Izinkan penyimpanan situs agar progres bertahan."
	hint_time = 3.0

func _process(delta: float) -> void:
	hint_time = maxf(0,hint_time-delta)
	saved_hint.visible = hint_time>0
	if chapter.stage==chapter.Stage.MENU or GameState.chapter_id(chapter)==0: return
	if not GameState.campaign_active: GameState.begin_chapter(chapter)
	if GameState.dialogue_active or chapter.paused or chapter.player.dead: return
	autosave_time += delta
	var signature := "%s/%s/%s" % [chapter.stage,chapter.get("mission"),chapter.facts_unlocked]
	if autosave_time>=15 or signature!=last_signature:
		if GameState.save_campaign(chapter):
			last_signature = signature
			autosave_time = 0

func _input(event: InputEvent) -> void:
	if event.is_echo(): return
	if event.is_action_pressed("world_map"):
		if is_instance_valid(map_layer): close_map()
		else: show_map()
		get_viewport().set_input_as_handled()
	elif is_instance_valid(map_layer) and event.is_action_pressed("pause"):
		close_map()
		get_viewport().set_input_as_handled()

func show_map() -> void:
	if is_instance_valid(map_layer): return
	if GameState._transition_busy: return
	if GameState.dialogue_active:
		chapter._notify("Selesaikan percakapan sebelum membuka peta.")
		return
	if chapter.get("ending_director")!=null and is_instance_valid(chapter.get("ending_director")): return
	if (chapter.stage==chapter.Stage.MENU or (GameState.chapter_id(chapter)==0 and not is_instance_valid(GameState.encounter_chapter))) and not GameState.campaign_active:
		if not GameState.load_campaign():
			chapter._notify("Mulai perjalanan untuk membuka peta.")
			return
	was_paused = chapter.paused
	was_tree_paused = get_tree().paused
	chapter.paused = true
	get_tree().paused = true
	map_layer = CanvasLayer.new()
	map_layer.layer = 40
	map_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(map_layer)
	map_root = Control.new()
	map_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_layer.add_child(map_root)
	var dim := ColorRect.new()
	dim.color = Color("071512f5")
	dim.size = Vector2(1280,720)
	map_root.add_child(dim)
	chapter._label(map_root,"JALAN YANG TELAH DIBUKA",Rect2(40,26,1000,44),30,chapter.GOLD)
	chapter._paragraph(map_root,"Teleport menuju gubuk. Patroli biasa kembali; misi, upgrade, dan kemenangan boss tetap tersimpan.",Rect2(40,76,1180,44),17,chapter.PAPER)
	var images := ["01-Tegalrejo.png","02-Jalur-Hutan.png","03-Selarong.png","04-Pemukiman-Terdampak.png","05-Magelang.png"]
	for index in range(5):
		var id := index+1
		var x := 40+index*242
		var opened := id<=GameState.unlocked_chapter
		var panel: Control = chapter._panel(map_root,Rect2(x,139,230,355),Color("142d29"),Color("b99b67") if opened else Color("34463d"))
		var thumbnail := Control.new()
		thumbnail.position = Vector2(8,8)
		thumbnail.size = Vector2(214,170)
		thumbnail.clip_contents = true
		panel.add_child(thumbnail)
		var art := TextureRect.new()
		var source: Texture2D = load("res://assets/Asset in game/peta/"+images[index])
		var preview := AtlasTexture.new()
		preview.atlas = source
		preview.region = Rect2(0,source.get_height()*0.22,source.get_width(),source.get_height()*0.60)
		art.texture = preview
		art.size = Vector2(214,170)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.modulate = Color.WHITE if opened else Color(0.32,0.38,0.36)
		thumbnail.add_child(art)
		chapter._label(panel,"%02d / %s" % [id,GameState.CHAPTER_NAMES[index]],Rect2(12,190,210,28),17,chapter.GOLD if opened else chapter.MUTED)
		chapter._paragraph(panel,"Selesai • dapat dikunjungi" if GameState.completed_chapters.has(id) else ("Daerah terbuka" if opened else "Selesaikan bab sebelumnya"),Rect2(12,226,210,47),15,chapter.MUTED)
		var button: Button = chapter._button(panel,"Teleport" if opened else "Terkunci",Rect2(12,290,206,46),func() -> void:
			close_map()
			GameState.travel_to(id,chapter))
		button.disabled = not opened
		button.add_theme_font_size_override("font_size",17)
		if not opened:
			var lock := LockIcon.new()
			lock.position = Vector2(100,70)
			lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(lock)
	var bosses: Array[String] = []
	for entry in [["buto","Buto Ijo"],["banaspati","Banaspati"],["headless","Headless Swordsman"]]:
		bosses.append(("✓ " if GameState.night_boss_defeated.get(entry[0],false) else "○ ")+entry[1])
	chapter._label(map_root,"LEGENDA MALAM  /  "+"    •    ".join(bosses),Rect2(40,524,1200,30),18,chapter.GOLD)
	chapter._paragraph(map_root,"Penutup rahasia: kalahkan ketiga legenda dan komandan Magelang. Kemenangan arena uji tidak dihitung.",Rect2(40,564,1200,40),17,chapter.MUTED)
	var save_status: Label = chapter._label(map_root,"",Rect2(360,648,400,30),18,chapter.GOLD)
	chapter._button(map_root,"Simpan perjalanan",Rect2(40,638,300,48),func() -> void:
		if GameState.save_campaign():
			save_status.text = "Tersimpan")
	chapter._button(map_root,"Kembali [M / Esc]",Rect2(940,638,300,48),close_map,true)

func close_map() -> void:
	if not is_instance_valid(map_layer): return
	map_layer.queue_free()
	map_layer = null
	chapter.paused = was_paused
	get_tree().paused = was_tree_paused

extends Node2D
## Chapter 1 owns progression; actors only report actions and damage.
const INK := Color("142b2a")
const GOLD := Color("e8c581")
const PAPER := Color("fff2d4")
const MUTED := Color("a9bbb1")
const FLOOR_Y := 570.0
const WORLD_WIDTH := 3800.0
const ActorVisual = preload("res://scripts/actor_visual.gd")
enum Stage { MENU, INTRO, EXPLORE, WARNING, AFTERMATH, EXIT, TRANSITION, COMPLETE, FAILED }

var stage: Stage = Stage.MENU
var story: Dictionary
var world: Node2D
var player: CharacterBody2D
var cat: Sprite2D
var camera: Camera2D
var mountains: Node2D
var sari: Node2D
var wirya: Node2D
var sari_area: Area2D
var messenger_area: Area2D
var guard_area: Area2D
var exit_area: Area2D
var ui: Control
var hud: Control
var menu: Control
var objective_label: Label
var health_label: Label
var chapter_steps: Label
var dialogue_box: Control
var speaker_label: Label
var dialogue_label: RichTextLabel
var dialogue_counter: Label
var portrait: TextureRect
var choice_container: Control
var choice_active: bool = false
var prompt: Label
var notice: Label
var overlay: Control
var overlay_panel: Control
var fade: ColorRect
var event_tint: ColorRect
var lines: Array = []
var line_index: int = 0
var dialogue_callback: Callable
var typing: float = 0.0
var elapsed: float = 0.0
var notice_time: float = 0.0
var facts_unlocked: int = 0
var paused: bool = false
var overlay_mode: String = ""
var exit_near: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.reset_stage()
	story = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_one.json"))
	_build_world()
	_build_ui()
	GameState.objective_updated.connect(func(text: String) -> void: objective_label.text = text)
	player.health_changed.connect(_health_changed)
	player.died.connect(_on_player_died)
	_health_changed(player.health, player.max_health)
	_set_menu()
	if GameState.start_on_load:
		GameState.start_on_load = false
		start_chapter()

func _build_world() -> void:
	var backdrop := CanvasLayer.new()
	backdrop.layer = -10
	add_child(backdrop)
	var sky := TextureRect.new()
	sky.texture = load("res://assets/Background/Tegalrejo/tegalrejo_sky.png")
	sky.position = Vector2.ZERO
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
	for i in range(-1, 4):
		_region_sprite(mountains, "res://assets/Background/Tegalrejo/tegalrejo_mountains.png", Rect2(0, 330, 2172, 310), Vector2(i * 1500, 265), Vector2(0.7, 0.7))
	for i in range(3):
		_region_sprite(world, "res://assets/Background/Tegalrejo/tegalrejo_village.png", Rect2(0, 265, 2172, 355), Vector2(i * 1954 - 180, 266), Vector2(0.9, 0.9))
	for i in range(4):
		_region_sprite(world, "res://assets/Background/Tegalrejo/ground.png", Rect2(0, 346, 2172, 378), Vector2(i * 1303 - 100, 564), Vector2(0.6, 0.6))
	_solid(Vector2(WORLD_WIDTH / 2, FLOOR_Y + 100), Vector2(WORLD_WIDTH + 400, 200))
	_solid(Vector2(-35, 340), Vector2(70, 700))
	_solid(Vector2(WORLD_WIDTH + 35, 340), Vector2(70, 700))
	var scenery := Node2D.new()
	scenery.set_script(load("res://scripts/scenery.gd"))
	world.add_child(scenery)
	player = preload("res://player.tscn").instantiate()
	player.position = Vector2(230, FLOOR_Y)
	world.add_child(player)
	if not player.is_in_group("player"):
		player.add_to_group("player")
	cat = ActorVisual.make_sprite("res://assets/Karakter/Cuking Taby.png", 39.0, Rect2(279, 118, 999, 822))
	cat.position = Vector2(155, FLOOR_Y - 19.5)
	world.add_child(cat)
	sari = _npc("Sesepuh", "res://assets/Karakter/sesepuh.png", Rect2(264,102,499,1377), 900)
	wirya = _npc("Utusan", "res://assets/Karakter/NPC cwo.png", Rect2(253,150,483,1330), 1510)
	sari_area = _area(Vector2(900, FLOOR_Y - 60), Vector2(210, 180))
	sari_area.set_script(load("res://interactable.gd"))
	# The script is attached after entering the tree; wire the reusable area's ready hook explicitly.
	sari_area._ready()
	sari_area.interaction_requested.connect(_talk_to_elder)
	messenger_area = _area(Vector2(1510, FLOOR_Y - 60), Vector2(210, 180))
	messenger_area.set_script(load("res://interactable.gd"))
	messenger_area._ready()
	messenger_area.interaction_requested.connect(_talk_to_messenger)
	_npc("Penjaga", "res://assets/Karakter/Penjaga Selarong.png", Rect2(), 3300)
	guard_area = _area(Vector2(3300, FLOOR_Y - 60), Vector2(210, 180))
	guard_area.set_script(load("res://interactable.gd"))
	guard_area._ready()
	guard_area.interaction_requested.connect(_deliver_message)
	exit_area = _area(Vector2(3550, FLOOR_Y - 80), Vector2(160, 240))
	exit_area.body_entered.connect(func(body: Node2D) -> void:
		if body == player:
			exit_near = true
			if stage == Stage.EXIT:
				_begin_transition()
			elif stage in [Stage.EXPLORE, Stage.WARNING, Stage.AFTERMATH]:
				_notify("Selesaikan tujuan terlebih dahulu. Jalur belum aman."))
	exit_area.body_exited.connect(func(body: Node2D) -> void:
		if body == player: exit_near = false)
	camera = Camera2D.new()
	camera.position = Vector2(640, 360)
	camera.limit_left = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 720
	world.add_child(camera)
	_world_label("TEGALREJO", Vector2(100, 495), 22, GOLD)
	_world_label("JALUR KELUAR  >", Vector2(3320, 405), 19, GOLD)

func _region_sprite(parent: Node, path: String, region: Rect2, at: Vector2, factor: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = false
	sprite.position = at
	sprite.scale = factor
	parent.add_child(sprite)
	return sprite

func _solid(at: Vector2, dimensions: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	world.add_child(body)

func _area(at: Vector2, dimensions: Vector2) -> Area2D:
	var area := Area2D.new()
	area.position = at
	area.collision_layer = 0
	area.collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	collision.shape = shape
	area.add_child(collision)
	world.add_child(area)
	return area

func _npc(npc_name: String, path: String, region: Rect2, x: float) -> Node2D:
	var actor := Node2D.new()
	actor.position = Vector2(x, FLOOR_Y)
	actor.add_child(ActorVisual.make_sprite(path, 117, region))
	world.add_child(actor)
	var tag := _label(actor, npc_name, Rect2(-70, -153, 140, 30), 18, PAPER)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_color_override("font_shadow_color", INK)
	tag.add_theme_constant_override("shadow_offset_x", 2)
	tag.add_theme_constant_override("shadow_offset_y", 2)
	return actor

func _world_label(text: String, at: Vector2, font_size: int, color: Color) -> void:
	var label := _label(world, text, Rect2(at, Vector2(330, 40)), font_size, color)
	label.add_theme_color_override("font_shadow_color", INK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)

func _style(bg: Color, border: Color = Color.TRANSPARENT, radius: int = 9) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _panel(parent: Node, bounds: Rect2, bg: Color = INK, border: Color = Color("47605a")) -> Panel:
	var p := Panel.new()
	p.position = bounds.position
	p.size = bounds.size
	p.add_theme_stylebox_override("panel", _style(bg, border))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

func _label(parent: Node, text: String, bounds: Rect2, font_size: int = 20, color: Color = PAPER) -> Label:
	var label := Label.new()
	label.text = text
	label.position = bounds.position
	label.size = bounds.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _paragraph(parent: Node, text: String, bounds: Rect2, font_size: int = 20, color: Color = PAPER) -> Label:
	var label := _label(parent, text, bounds, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _button(parent: Node, text: String, bounds: Rect2, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.position = bounds.position
	button.size = bounds.size
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", INK if primary else PAPER)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", INK if primary else PAPER)
	button.add_theme_stylebox_override("normal", _style(GOLD if primary else Color("203e39"), GOLD if primary else Color("48665d")))
	button.add_theme_stylebox_override("hover", _style(Color("f4dab0"), GOLD))
	button.add_theme_stylebox_override("pressed", _style(Color("bca16b"), GOLD))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, PAPER))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	event_tint = ColorRect.new()
	event_tint.size = Vector2(1280,720)
	event_tint.color = Color(0.28,0.13,0.05,0)
	event_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(event_tint)
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	_panel(hud, Rect2(28,24,570,108), Color("142b2af2"))
	_label(hud, "01  /  TEGALREJO", Rect2(48,36,320,28),18,GOLD)
	chapter_steps = _label(hud,"JULI 1825",Rect2(414,36,164,28),16,MUTED)
	objective_label = _paragraph(hud,"",Rect2(48,70,530,52),22)
	_panel(hud,Rect2(1024,24,228,86),Color("142b2af2"))
	_label(hud,"JAKA",Rect2(1044,36,100,22),16,GOLD)
	health_label = _label(hud,"",Rect2(1044,64,190,30),22)
	_panel(hud,Rect2(28,662,1224,38),Color("142b2ae6"))
	_label(hud,"A D / PANAH   Gerak       SPACE   Lompat       E   Bicara       1 / 2   Pilih jawaban",Rect2(45,669,930,25),16)
	_label(hud,"J  Tembak    T  Catatan    ESC  Jeda",Rect2(966,669,275,25),15,GOLD)
	prompt = _label(hud,"",Rect2(390,392,500,44),21,GOLD)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_shadow_color",INK)
	prompt.add_theme_constant_override("shadow_offset_x",2)
	prompt.add_theme_constant_override("shadow_offset_y",2)
	notice = _label(hud,"",Rect2(220,146,840,46),19,PAPER)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_stylebox_override("normal",_style(Color("142b2ae6")))
	notice.hide()
	# Place the conversation over the sky so Jaka and the village remain visible.
	dialogue_box = _panel(ui,Rect2(28,153,1224,155),Color("102826ed"),GOLD)
	portrait = TextureRect.new()
	portrait.position = Vector2(18,11)
	portrait.size = Vector2(96,135)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dialogue_box.add_child(portrait)
	speaker_label = _label(dialogue_box,"",Rect2(135,12,1025,30),21,GOLD)
	dialogue_label = RichTextLabel.new()
	dialogue_label.position = Vector2(135,45)
	dialogue_label.size = Vector2(1035,78)
	dialogue_label.add_theme_font_size_override("normal_font_size",21)
	dialogue_label.add_theme_color_override("default_color",PAPER)
	dialogue_label.scroll_active = false
	dialogue_box.add_child(dialogue_label)
	dialogue_counter = _label(dialogue_box,"",Rect2(135,126,1020,22),15,MUTED)
	dialogue_box.hide()
	choice_container = Control.new()
	ui.add_child(choice_container)
	choice_container.hide()
	menu = Control.new()
	ui.add_child(menu)
	_panel(menu,Rect2(0,0,630,720),Color("0b1515fa"),Color.TRANSPARENT)
	var menu_accent := Color("bd6853")
	var accent_line := ColorRect.new()
	accent_line.position = Vector2(64, 113)
	accent_line.size = Vector2(235, 3)
	accent_line.color = menu_accent
	menu.add_child(accent_line)
	_label(menu,"SEBUAH KISAH DARI JAWA",Rect2(64,72,500,28),17,GOLD)
	var title := _label(menu,"JEJAK\nTANAH JAWA",Rect2(60,135,545,172),63,PAPER)
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia","DejaVu Serif"])
	title.add_theme_font_override("font",serif)
	_label(menu,"BAB 01   /   TEGALREJO, JULI 1825",Rect2(64,316,500,35),19,GOLD)
	_paragraph(menu,"Di tengah desa yang diliputi ketegangan,\nlangkah kecil Jaka menjadi awal sebuah perjalanan.",Rect2(64,366,490,83),22)
	_button(menu,"Mulai perjalanan   >",Rect2(64,480,440,58),start_chapter,true)
	_button(menu,"Tentang kisah ini",Rect2(64,554,274,46),_show_about)
	_button(menu,"Keluar",Rect2(350,554,154,46),func() -> void: get_tree().quit())
	_paragraph(menu,"Petualangan sejarah 2D  /  Keyboard\nJaka dan percakapannya adalah dramatisasi fiksi.",Rect2(64,643,510,48),15,MUTED)
	_panel(menu,Rect2(967,42,265,74),Color("11191bf2"),menu_accent)
	_label(menu,"01",Rect2(986,48,56,50),37,GOLD)
	_label(menu,"AWAL PERJALANAN\nTegalrejo",Rect2(1050,54,176,45),16,PAPER)
	overlay = Control.new()
	ui.add_child(overlay)
	overlay.hide()
	fade = ColorRect.new()
	fade.size = Vector2(1280,720)
	fade.color = Color(0.03,0.08,0.07,0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade)

func _set_menu() -> void:
	stage = Stage.MENU
	player.controls_enabled = false
	menu.show()
	hud.hide()
	camera.position.x = 640

func start_chapter() -> void:
	menu.hide()
	hud.show()
	stage = Stage.INTRO
	GameState.set_objective("Temui sesepuh desa di Tegalrejo.")
	_start_dialogue(story.intro,func() -> void:
		stage = Stage.EXPLORE
		player.controls_enabled = true
		_notify("Temui sesepuh di sebelah kanan. Tekan E untuk bicara."))

func _process(delta: float) -> void:
	if paused:
		return
	if stage not in [Stage.MENU,Stage.COMPLETE,Stage.FAILED]:
		elapsed += delta
	if GameState.dialogue_active:
		typing += delta * 48.0
		dialogue_label.visible_characters = int(typing)
	if stage != Stage.MENU:
		camera.position.x = lerpf(camera.position.x, clampf(player.position.x + 180,640,WORLD_WIDTH-640),1.0-exp(-delta*5))
	mountains.position.x = (camera.position.x-640)*0.65
	var cat_target := Vector2(player.position.x - player.facing * 66, FLOOR_Y)
	if absf(cat.position.x-cat_target.x)>12:
		cat.position.x = move_toward(cat.position.x,cat_target.x,delta*235)
		cat.flip_h = cat_target.x < cat.position.x
		cat.position.y = FLOOR_Y - 19.5 - absf(sin(elapsed*10))*3
	else:
		cat.position.y = FLOOR_Y - 19.5
	prompt.text = ""
	if stage == Stage.EXPLORE and sari_area.player_near and not GameState.dialogue_active:
		prompt.text = "[ E ]  Bicara dengan sesepuh"
	elif stage == Stage.WARNING and messenger_area.player_near and not GameState.dialogue_active:
		prompt.text = "[ E ]  Bicara dengan utusan"
	elif stage == Stage.AFTERMATH and guard_area.player_near and not GameState.dialogue_active:
		prompt.text = "[ E ]  Antarkan pesan kepada penjaga"
	elif stage == Stage.EXIT:
		prompt.text = "Pesan tersampaikan. Lanjutkan ke kanan  >"
		if exit_near:
			_begin_transition()
	if notice_time > 0:
		notice_time -= delta
		notice.visible = notice_time > 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("pause"):
		if overlay.visible and overlay_mode in ["pause","journal","about"]:
			_close_overlay()
		elif stage not in [Stage.MENU,Stage.COMPLETE,Stage.FAILED]:
			_show_pause()
		get_viewport().set_input_as_handled()
		return
	if paused or overlay.visible:
		return
	if event.is_action_pressed("journal") and stage in [Stage.EXPLORE,Stage.WARNING,Stage.AFTERMATH,Stage.EXIT]:
		_show_journal()
		get_viewport().set_input_as_handled()
		return
	if GameState.dialogue_active and choice_active and event is InputEventKey and event.pressed:
		if event.keycode in [KEY_1, KEY_KP_1]:
			_choose(0)
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_2, KEY_KP_2]:
			_choose(1)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("interact"):
		if GameState.dialogue_active:
			advance_dialogue()
		elif stage == Stage.EXPLORE:
			sari_area.trigger_interaction()
		elif stage == Stage.WARNING:
			messenger_area.trigger_interaction()
		elif stage == Stage.AFTERMATH:
			guard_area.trigger_interaction()
		get_viewport().set_input_as_handled()

func _talk_to_elder() -> void:
	if stage != Stage.EXPLORE:
		return
	_start_dialogue(story.elder,func() -> void:
		facts_unlocked = 2
		stage = Stage.WARNING
		GameState.set_objective("Temui utusan di tengah desa.")
		_notify("Sesepuh telah menjelaskan keadaan. Temui utusan di kanan."))

func _talk_to_messenger() -> void:
	if stage != Stage.WARNING:
		return
	_start_dialogue(story.messenger,func() -> void:
		stage = Stage.AFTERMATH
		GameState.set_objective("Antarkan pesan kepada penjaga di ujung desa.")
		_notify("Cari penjaga di dekat jalur keluar desa."))

func _deliver_message() -> void:
	if stage != Stage.AFTERMATH:
		return
	_start_dialogue(story.delivery,func() -> void:
		facts_unlocked = 3
		stage = Stage.EXIT
		GameState.set_objective("Pesan tersampaikan. Cari jalur keluar!",true)
		_notify("Catatan sejarah baru tersimpan. Tekan T untuk membacanya."))

func _start_dialogue(content: Array, completed: Callable) -> void:
	if content.is_empty():
		completed.call()
		return
	lines = content.duplicate(true)
	line_index = 0
	dialogue_callback = completed
	GameState.dialogue_active = true
	GameState.dialogue_started.emit()
	player.velocity.x = 0
	notice_time = 0
	notice.hide()
	dialogue_box.show()
	_show_line()

func _show_line() -> void:
	var line: Dictionary = lines[line_index]
	speaker_label.text = line.speaker
	dialogue_label.text = line.text
	typing = 0
	dialogue_label.visible_characters = 0
	dialogue_counter.text = "%d / %d     •     E  Tampilkan / lanjutkan" % [line_index+1, lines.size()]
	_show_choices(line)
	var path := "res://assets/Karakter/Jaka.png"
	var region := Rect2(270,83,510,1370)
	if line.speaker == "Sesepuh":
		path = "res://assets/Karakter/sesepuh.png"
		region = Rect2(264,102,499,1377)
	elif line.speaker == "Utusan":
		path = "res://assets/Karakter/NPC cwo.png"
		region = Rect2(253,150,483,1330)
	elif line.speaker == "Penjaga":
		path = "res://assets/Karakter/Penjaga Selarong.png"
		region = Rect2(0,0,1024,1536)
	portrait.visible = line.speaker != "Narator"
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path)
	atlas.region = region
	portrait.texture = atlas

func advance_dialogue() -> void:
	if not GameState.dialogue_active:
		return
	if dialogue_label.visible_characters < dialogue_label.get_total_character_count():
		typing = float(dialogue_label.get_total_character_count())
		dialogue_label.visible_characters = int(typing)
		return
	if choice_active:
		_choose(0)
		return
	line_index += 1
	if line_index < lines.size():
		_show_line()
		return
	dialogue_box.hide()
	choice_container.hide()
	GameState.dialogue_active = false
	GameState.dialogue_ended.emit()
	var callback := dialogue_callback
	dialogue_callback = Callable()
	if callback.is_valid():
		callback.call()

func _show_choices(line: Dictionary) -> void:
	for child in choice_container.get_children():
		choice_container.remove_child(child)
		child.queue_free()
	choice_active = line.has("choices")
	choice_container.visible = choice_active
	if not choice_active:
		return
	var card := _panel(choice_container,Rect2(705,310,547,105),Color("102826f2"),GOLD)
	_label(card,"JAKA  /  PILIH JAWABAN",Rect2(18,5,510,20),15,GOLD)
	var choices: Array = line.choices
	for i in range(choices.size()):
		var index: int = i
		_button(card,"%d   %s" % [i+1,choices[i].text],Rect2(18,27+i*35,510,32),func() -> void: _choose(index),i==0)

func _choose(index: int) -> void:
	if not choice_active or not GameState.dialogue_active:
		return
	var current: Dictionary = lines[line_index]
	var choices: Array = current.choices
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	choice_active = false
	choice_container.hide()
	lines.insert(line_index+1,{"speaker":"Jaka","text":choice.text})
	lines.insert(line_index+2,{"speaker":current.speaker,"text":choice.reply})
	line_index += 1
	_show_line()

func _begin_transition() -> void:
	if stage != Stage.EXIT or not GameState.objective_completed:
		return
	stage = Stage.TRANSITION
	player.controls_enabled = false
	GameState.ending_started = true
	_start_dialogue(story.transition,_complete)

func _complete() -> void:
	stage = Stage.COMPLETE
	show_result(true)

func _on_player_died() -> void:
	if stage == Stage.FAILED:
		return
	stage = Stage.FAILED
	player.controls_enabled = false
	GameState.ending_started = true
	show_result(false)

func _health_changed(current: int, maximum: int) -> void:
	health_label.text = "● ".repeat(maxi(current,0)) + "○ ".repeat(maxi(maximum-current,0))

func _notify(text: String) -> void:
	notice.text = text
	notice_time = 5
	notice.show()

func _new_overlay(mode: String, title: String, subtitle: String) -> Control:
	for child in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()
	overlay_mode = mode
	var dim := ColorRect.new()
	dim.size = Vector2(1280,720)
	dim.color = Color(0.025,0.07,0.065,0.84)
	overlay.add_child(dim)
	overlay_panel = _panel(overlay,Rect2(210,70,860,580),Color("142b2a"),GOLD)
	_label(overlay_panel,title,Rect2(40,30,780,55),35,GOLD)
	_paragraph(overlay_panel,subtitle,Rect2(40,95,780,70),20,PAPER)
	overlay.show()
	return overlay_panel

func _show_pause() -> void:
	paused = true
	get_tree().paused = true
	var box := _new_overlay("pause","Perjalanan dijeda","Ambil waktu sejenak. Perjalananmu di Tegalrejo menunggu.")
	_button(box,"Lanjutkan perjalanan",Rect2(40,190,780,58),_close_overlay,true)
	_button(box,"Ulangi Bab 1",Rect2(40,267,780,58),_restart)
	_button(box,"Menu utama",Rect2(40,344,780,58),_return_menu)
	_paragraph(box,"A / D atau panah: bergerak   •   Space: lompat\nE: bicara / lanjut dialog   •   J: serang   •   T: catatan sejarah",Rect2(40,458,780,80),18,MUTED)

func _show_journal() -> void:
	paused = true
	get_tree().paused = true
	var box := _new_overlay("journal","Catatan perjalanan","Fakta yang kamu temukan di Tegalrejo. Dialog dan pertarungan Jaka adalah dramatisasi fiksi.")
	var facts: Array = story.get("facts",[])
	for i in range(mini(facts.size(),3)):
		var fact: Dictionary = facts[i]
		_label(box,str(fact.title) if i<facts_unlocked else "%02d  /  Belum ditemukan" % (i+1),Rect2(40,180+i*101,780,28),20,GOLD)
		_paragraph(box,str(fact.text) if i<facts_unlocked else "Lanjutkan perjalanan untuk membuka catatan ini.",Rect2(40,213+i*101,780,66),17,PAPER)
	_button(box,"Kembali",Rect2(40,505,780,46),_close_overlay,true)

func _show_about() -> void:
	var box := _new_overlay("about","Tentang kisah ini","Jejak Tanah Jawa • Bab 1: Tegalrejo\nPetualangan sejarah dengan Jaka dan kucing pendampingnya.")
	_paragraph(box,"Latar sejarah: pergolakan di Tegalrejo pada Juli 1825 dan awal perlawanan Diponegoro.\n\nJaka, Sari, Wirya, dialog, dan pertempuran dalam permainan merupakan fiksi. Mereka tidak mengubah hasil sejarah.\n\nRujukan: Museum Benteng Vredeburg dan sumber pemerintah yang dicatat pada docs/HISTORY.md. Aset visual disediakan oleh tim proyek.",Rect2(40,190,780,250),21)
	_button(box,"Kembali",Rect2(40,490,780,58),_close_overlay,true)

func _close_overlay() -> void:
	overlay.hide()
	paused = false
	get_tree().paused = false

func show_result(success: bool) -> void:
	hud.hide()
	var box := _new_overlay("result","Bab 1 selesai" if success else "Perjalanan belum berakhir", "Pesanmu sudah sampai. Perjalanan Jaka kini menuju jalur Selarong." if success else "Perjalanan Jaka terhenti sebelum keluar dari desa. Coba mulai kembali.")
	if success:
		_label(box,"TEGALREJO     - - - - - - - - - - - - >     SELARONG",Rect2(40,198,780,40),24,GOLD)
		_paragraph(box,"Juli 1825\nSetelah serangan di Tegalrejo, Diponegoro mundur ke Selarong dan menjadikannya basis awal perlawanan.",Rect2(40,270,780,100),23)
		_label(box,"Pesan tersampaikan    •    3 catatan sejarah ditemukan",Rect2(40,397,780,35),19,MUTED)
		_label(box,"Bab 2: Jalur menuju Selarong masih dalam pengembangan.",Rect2(40,441,780,30),17,MUTED)
	else:
		_paragraph(box,"Petunjuk\n\nTemui sesepuh, lalu utusan di tengah desa. Antarkan pesan kepada penjaga dekat gerbang sebelum berjalan ke kanan.",Rect2(40,210,780,220),23)
	_button(box,"Main lagi",Rect2(40,494,380,58),_restart,true)
	_button(box,"Menu utama",Rect2(440,494,380,58),_return_menu)

func _restart() -> void:
	GameState.start_on_load = true
	get_tree().paused = false
	get_tree().reload_current_scene()

func _return_menu() -> void:
	GameState.start_on_load = false
	get_tree().paused = false
	get_tree().reload_current_scene()

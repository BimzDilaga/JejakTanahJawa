extends Node2D
const SARI_IMAGE := "res://assets/Karakter/WAIFU .png"
const SARI_REGION := Rect2(303, 127, 416, 1364)
const PROLOGUE := [
	{"speaker": "Narator", "text": "Tegalrejo, Juli 1825. Menjelang petang, Sari masih berada di jalan desa ketika para warga mulai menutup pintu rumah."},
	{"speaker": "Sari", "text": "Di dekat makam aku melihat patok baru. Orang-orang berkumpul, dan tak seorang pun tahu apakah jalan itu masih aman besok."},
	{"speaker": "Sari", "text": "Aku akan beri tahu keluarga di ujung desa. Kalau Jaka datang, minta dia menemui sesepuh. Beliau tahu apa yang terjadi."},
	{"speaker": "Narator", "text": "Sari pun pergi menyusuri pematang. Tak lama kemudian, Jaka tiba di Tegalrejo."},
]
## Chapter 1 owns progression; actors only report actions and damage.
const INK := Color("142b2a")
const GOLD := Color("e8c581")
const PAPER := Color("fff2d4")
const MUTED := Color("a9bbb1")
const FLOOR_Y := 570.0
const WORLD_WIDTH := 3800.0
const CAMERA_ZOOM := 1.25
const CAMERA_Y := 460.0
const CAMERA_HALF_WIDTH := 640.0 / CAMERA_ZOOM
const ActorVisual = preload("res://scripts/actor_visual.gd")
const DayNight = preload("res://scripts/day_night_cycle.gd")
const Atmosphere = preload("res://scripts/ambient_atmosphere.gd")
enum Stage { MENU, INTRO, EXPLORE, WARNING, AFTERMATH, EXIT, TRANSITION, COMPLETE, FAILED }

var stage: Stage = Stage.MENU
var story: Dictionary
var world: Node2D
var player: CharacterBody2D
var cat: AnimatedSprite2D
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
var health_icons: Array[TextureRect] = []
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
var day_night: CanvasLayer
var time_label: Label
var atmosphere: Node2D
var night_events: Node
var upgrade_hut: Node
var journey: Node
var world_audio: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.reset_stage()
	story = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_one.json"))
	_build_world()
	_build_ui()
	day_night = DayNight.new()
	day_night.name = "DayNightCycle"
	day_night.chapter = self
	day_night.phase_label = time_label
	add_child(day_night)
	atmosphere = Atmosphere.new()
	atmosphere.name = "Atmosphere"
	atmosphere.camera = camera
	atmosphere.embers = get("kind")=="banaspati"
	atmosphere.mist = not get_script().resource_path.ends_with("chapter_one.gd")
	atmosphere.wooded = get_script().resource_path.get_file() in ["chapter_two.gd","chapter_three.gd","boss_arena.gd"]
	world.add_child(atmosphere)
	world_audio = preload("res://scripts/world_audio.gd").new()
	world_audio.chapter = self
	world.add_child(world_audio)
	GameState.objective_updated.connect(func(text: String) -> void: objective_label.text = text)
	player.health_changed.connect(_health_changed)
	player.died.connect(_on_player_died)
	_health_changed(player.health, player.max_health)
	_set_menu()
	if get_script().resource_path.get_file()!="boss_arena.gd":
		upgrade_hut = preload("res://scripts/upgrade_hut.gd").new()
		upgrade_hut.chapter = self
		add_child(upgrade_hut)
	if get_script().resource_path.get_file() in ["chapter_one.gd","chapter_two.gd","chapter_four.gd"]:
		night_events = preload("res://scripts/night_encounters.gd").new()
		night_events.chapter = self
		add_child(night_events)
	if GameState.start_on_load:
		GameState.start_on_load = false
		start_chapter()
	journey = preload("res://scripts/journey_session.gd").new()
	journey.chapter = self
	add_child(journey)

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
	var mountain_region := Rect2(0, 330, 2172, 300)
	var mountain_scale := Vector2(0.7, 1.02)
	var mountain_width := mountain_region.size.x * mountain_scale.x
	for i in range(-1, 4):
		var tile := _region_sprite(mountains, "res://assets/Background/Tegalrejo/tegalrejo_mountains.png", mountain_region, Vector2(i * mountain_width, 261), mountain_scale)
		# Mirrored tiles meet at matching edges of the ridge.
		tile.flip_h = posmod(i, 2) == 1
	for i in range(3):
		var village := _region_sprite(world, "res://assets/Background/Tegalrejo/tegalrejo_village.png", Rect2(0, 265, 2172, 355), Vector2(i * 1900 - 180, 266), Vector2(0.9, 0.9))
		if i > 0:
			village.material = _horizontal_fade(0.0, 0.03, false)
	_ground_art(-100, WORLD_WIDTH+200)
	_solid(Vector2(WORLD_WIDTH / 2, FLOOR_Y + 100), Vector2(WORLD_WIDTH + 400, 200))
	_solid(Vector2(-35, 340), Vector2(70, 700))
	_solid(Vector2(WORLD_WIDTH + 35, 340), Vector2(70, 700))
	var scenery := Node2D.new()
	scenery.set_script(load("res://scripts/scenery.gd"))
	world.add_child(scenery)
	_add_walker("female", 575.0, 470.0, 675.0)
	_add_walker("male", 2280.0, 2140.0, 2420.0, -1.0)
	player = preload("res://player.tscn").instantiate()
	player.position = Vector2(230, FLOOR_Y)
	world.add_child(player)
	if not player.is_in_group("player"):
		player.add_to_group("player")
	cat = _make_cat(Vector2(155, FLOOR_Y - 56.0))
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
	camera.position = Vector2(640, CAMERA_Y)
	camera.zoom = Vector2.ONE * CAMERA_ZOOM
	camera.limit_left = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 800
	world.add_child(camera)
	_world_label("TEGALREJO", Vector2(100, 495), 22, GOLD)
	_world_label("JALUR KELUAR  >", Vector2(3395, 244), 19, GOLD)
	_add_upgrade_hut(1200.0)

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

func _horizontal_fade(start: float, finish: float, fade_out: bool) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform float fade_start; uniform float fade_end; uniform bool fade_out; void fragment(){ vec4 color = texture(TEXTURE, UV); float fade = smoothstep(fade_start, fade_end, UV.x); color.a *= fade_out ? 1.0 - fade : fade; COLOR = color; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("fade_start", start)
	material.set_shader_parameter("fade_end", finish)
	material.set_shader_parameter("fade_out", fade_out)
	return material

func _ground_art(x: float, width: float) -> void:
	var ground := TextureRect.new()
	ground.name = "GroundArt"
	ground.texture = load("res://assets/Background/Tanah Baru.png")
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Image surface is at source y=560; the collision floor is at world y=570.
	ground.position = Vector2(x,FLOOR_Y-26)
	ground.size = Vector2(width,400)
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/ground_strip.gdshader")
	material.set_shader_parameter("strip_size",ground.size)
	material.set_shader_parameter("world_x",x)
	ground.material = material
	world.add_child(ground)

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

func _make_cat(at: Vector2) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Taby"
	sprite.sprite_frames = ActorVisual.cat_frames()
	sprite.position = at
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	world.add_child(sprite)
	sprite.play("groom")
	return sprite

func _update_cat_animation(moving: bool, jumping: bool) -> void:
	var animation := "jump" if jumping else ("walk" if moving else "groom")
	if cat.animation != animation:
		cat.play(animation)

func _add_walker(variant: String, start_x: float, left_x: float, right_x: float, direction: float = 1.0) -> Node2D:
	var walker := Node2D.new()
	walker.set_script(load("res://scripts/village_walker.gd"))
	walker.name = "WargaBerjalan_%d" % roundi(start_x)
	walker.variant = variant
	walker.left_x = left_x
	walker.right_x = right_x
	walker.direction = direction
	walker.position = Vector2(start_x, FLOOR_Y)
	world.add_child(walker)
	return walker

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

func _add_upgrade_hut(x: float) -> void:
	var hut := Node2D.new()
	hut.name = "UpgradeHut"
	hut.position = Vector2(x, FLOOR_Y)
	var walls := Polygon2D.new()
	walls.polygon = PackedVector2Array([Vector2(-55, 0), Vector2(-55, -62), Vector2(55, -62), Vector2(55, 0)])
	walls.color = Color("775540")
	hut.add_child(walls)
	var door := Polygon2D.new()
	door.polygon = PackedVector2Array([Vector2(-13, 0), Vector2(-13, -39), Vector2(13, -39), Vector2(13, 0)])
	door.color = Color("392b24")
	hut.add_child(door)
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([Vector2(-69, -57), Vector2(0, -98), Vector2(69, -57)])
	roof.color = Color("a07748")
	hut.add_child(roof)
	world.add_child(hut)
	world.move_child(hut, player.get_index())
	_world_label("GUBUK UPGRADE", Vector2(x - 83, FLOOR_Y - 126), 16, GOLD)

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
	health_label.hide()
	var badge := TextureRect.new()
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.texture = load("res://assets/Asset in game/heart/jaka_and_cat_only.png")
	badge.position = Vector2(962, 27)
	badge.size = Vector2(64, 72)
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(badge)
	var heart := AtlasTexture.new()
	heart.atlas = load("res://assets/Asset in game/heart/hearts_only.png")
	heart.region = Rect2(0, 0, 280, 253)
	for index in range(player.max_health):
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.texture = heart
		icon.position = Vector2(1044 + index * 36, 65)
		icon.size = Vector2(30, 28)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud.add_child(icon)
		health_icons.append(icon)
	_panel(hud,Rect2(28,662,1224,38),Color("142b2ae6"))
	var stance_hud := preload("res://scripts/stance_meter.gd").new()
	stance_hud.name = "StanceMeter"
	stance_hud.player = player
	stance_hud.position = Vector2(1024, 146)
	stance_hud.size = Vector2(228, 72)
	hud.add_child(stance_hud)
	var stamina_hud := preload("res://scripts/stamina_meter.gd").new()
	stamina_hud.name = "StaminaMeter"
	stamina_hud.player = player
	stamina_hud.position = Vector2(1024,114)
	stamina_hud.size = Vector2(228,26)
	hud.add_child(stamina_hud)
	var time_badge := _panel(hud,Rect2(690,24,214,46),Color("142b2ae6"))
	time_label = _label(time_badge,"",Rect2(12,9,190,28),17,GOLD)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(hud,"A/D Jalan  •  Shift Dash / tahan Lari  •  S+Shift Mundur  •  Space Lompat  •  Klik kiri Combo  •  Klik kanan Parry  •  E Bicara",Rect2(45,669,1200,25),14)
	prompt = _label(hud,"",Rect2(390,392,500,44),21,GOLD)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_shadow_color",INK)
	prompt.add_theme_constant_override("shadow_offset_x",2)
	prompt.add_theme_constant_override("shadow_offset_y",2)
	notice = _label(hud,"",Rect2(220,146,840,46),19,PAPER)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_stylebox_override("normal",_style(Color("142b2ae6")))
	notice.hide()
	# Keep the conversation beneath the actors; the camera frames Jaka above it.
	dialogue_box = _panel(ui,Rect2(28,502,1224,152),Color("102826f2"),GOLD)
	dialogue_box.clip_contents = false
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.position = Vector2(10,-54)
	portrait.size = Vector2(174,198)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_box.add_child(portrait)
	speaker_label = _label(dialogue_box,"",Rect2(202,10,962,30),21,GOLD)
	dialogue_label = RichTextLabel.new()
	dialogue_label.position = Vector2(202,43)
	dialogue_label.size = Vector2(962,78)
	dialogue_label.add_theme_font_size_override("normal_font_size",21)
	dialogue_label.add_theme_color_override("default_color",PAPER)
	dialogue_label.scroll_active = false
	dialogue_box.add_child(dialogue_label)
	dialogue_counter = _label(dialogue_box,"",Rect2(202,122,962,22),15,MUTED)
	dialogue_box.hide()
	choice_container = Control.new()
	ui.add_child(choice_container)
	choice_container.hide()
	_build_title_menu()
	overlay = Control.new()
	ui.add_child(overlay)
	overlay.hide()
	fade = ColorRect.new()
	fade.size = Vector2(1280,720)
	fade.color = Color(0.03,0.08,0.07,0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade)

func _build_title_menu() -> void:
	menu = Control.new()
	menu.name = "TitleMenu"
	ui.add_child(menu)
	var picture := TextureRect.new()
	picture.name = "GeneratedTitleArtwork"
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var art_path := "res://assets/Generated/Menu/title-keyart-v1.png"
	picture.texture = load(art_path if ResourceLoader.exists(art_path) else "res://assets/Background/Tegalrejo/tegalrejo_village.png")
	picture.position = Vector2(-8,-6)
	picture.size = Vector2(1296,732)
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(picture)
	# Readability over the generated image, without building the scene from sprites.
	var veil := TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0,Color(0.015,0.025,0.025,0.26))
	gradient.set_color(1,Color(0.015,0.025,0.025,0))
	gradient.add_point(0.30,Color(0.015,0.025,0.025,0.12))
	gradient.add_point(0.42,Color(0.015,0.025,0.025,0))
	var fill := GradientTexture2D.new()
	fill.gradient = gradient
	fill.fill_from = Vector2.ZERO
	fill.fill_to = Vector2.RIGHT
	veil.texture = fill
	veil.size = Vector2(1280,720)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(veil)
	_label(menu,"TEGALREJO  /  JULI 1825",Rect2(58,45,420,26),14,GOLD)
	var title := _label(menu,"JEJAK\nTANAH JAWA",Rect2(54,98,470,136),53,PAPER)
	title.add_theme_color_override("font_shadow_color",Color("090e0dcc"))
	title.add_theme_constant_override("shadow_offset_x",3)
	title.add_theme_constant_override("shadow_offset_y",4)
	var serif := FontVariation.new()
	serif.base_font = preload("res://assets/Fonts/CormorantGaramond.ttf")
	serif.variation_opentype = {"wght":700.0}
	title.add_theme_font_override("font",serif)
	var line := ColorRect.new()
	line.position = Vector2(58,249)
	line.size = Vector2(173,2)
	line.color = GOLD.darkened(0.2)
	menu.add_child(line)
	var continue_button := _menu_button("Lanjutkan perjalanan",294,func() -> void: GameState.continue_campaign())
	continue_button.disabled = not GameState.has_save()
	_menu_button("Mulai perjalanan baru",344,_request_new_journey)
	_menu_button("Peta & progres",398,func() -> void: journey.show_map())
	_menu_button("Arena uji boss",442,_show_boss_trials)
	_menu_button("Pengaturan",486,_show_settings)
	_menu_button("Tentang kisah ini",530,_show_about)
	_menu_button("Keluar",574,func() -> void: get_tree().quit())
	_label(menu,"5 BAB  •  3 LEGENDA MALAM  •  3 ENDING",Rect2(58,646,500,24),12,GOLD)
	_label(menu,"Petualangan sejarah fantasi • Tokoh dan dialog Jaka adalah rekaan.",Rect2(58,679,650,22),12,MUTED)
	var motion := preload("res://scripts/title_menu_art.gd").new()
	motion.menu = menu
	motion.picture = picture
	menu.add_child(motion)

func _menu_button(text: String, y: float, callback: Callable) -> Button:
	var button := _button(menu,text,Rect2(58,y,380,42),callback)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size",23)
	button.add_theme_color_override("font_color",Color("d2d0bf"))
	button.add_theme_color_override("font_hover_color",PAPER)
	button.add_theme_color_override("font_focus_color",GOLD)
	button.add_theme_color_override("font_disabled_color",Color("626b65"))
	for state in ["normal","hover","pressed","focus","disabled"]:
		var style := StyleBoxEmpty.new()
		style.set_content_margin(SIDE_LEFT,26)
		button.add_theme_stylebox_override(state,style)
	var marker := _label(button,">",Rect2(0,10,20,24),14,GOLD)
	marker.hide()
	button.mouse_entered.connect(func() -> void:
		if not button.disabled: button.grab_focus())
	button.mouse_entered.connect(marker.show)
	button.mouse_exited.connect(func() -> void: marker.visible = button.has_focus())
	button.focus_entered.connect(marker.show)
	button.focus_exited.connect(func() -> void: marker.visible = button.is_hovered())
	return button

func _show_boss_trials() -> void:
	var box := _new_overlay("boss_trials","Arena uji boss","Latihan terpisah dari perjalanan. Kemenangan di sini tidak membuka syarat ending.")
	var names := {"buto":"Buto Ijo","banaspati":"Banaspati","headless":"Headless Swordsman","commander":"Komandan Belanda"}
	var index := 0
	for kind: String in names:
		_button(box,str(names[kind]),Rect2(40+(index%2)*400,205+(index/2)*90,380,68),func() -> void: _open_boss_trial(kind))
		index += 1
	_button(box,"Kembali",Rect2(40,444,780,54),_close_overlay,true)

func _show_settings() -> void:
	paused = true
	get_tree().paused = true
	var box := _new_overlay("settings","Pengaturan audio","Volume disimpan di perangkat ini dan tetap dipakai saat memulai perjalanan baru.")
	var names := {"Master":"Volume utama","Music":"Musik","SFX":"Efek pertarungan","Ambience":"Suara lingkungan"}
	var index := 0
	for key: String in names:
		_label(box,str(names[key]),Rect2(40,180+index*62,280,29),19,PAPER)
		var value := _label(box,"%d%%" % roundi(float(AudioPrefs.levels[key])*100),Rect2(710,180+index*62,100,29),18,GOLD)
		var slider := HSlider.new()
		slider.position = Vector2(330,183+index*62)
		slider.size = Vector2(350,28)
		slider.max_value = 100
		slider.step = 1
		slider.value = float(AudioPrefs.levels[key])*100
		slider.value_changed.connect(func(amount: float) -> void:
			AudioPrefs.set_level(key,amount/100)
			value.text = "%d%%" % roundi(amount))
		box.add_child(slider)
		index += 1
	_button(box,"Kembali",Rect2(40,476,780,54),_close_overlay,true)

func _set_menu() -> void:
	stage = Stage.MENU
	player.controls_enabled = false
	menu.show()
	hud.hide()
	camera.position.x = CAMERA_HALF_WIDTH
	for child in menu.get_children():
		if child is Button and not child.disabled:
			child.grab_focus()
			break

func _open_boss_trial(kind: String) -> void:
	GameState.boss_trial_kind = kind
	GameState.start_on_load = false
	get_tree().change_scene_to_file("res://boss_trial.tscn")

func _start_new_journey() -> void:
	GameState.reset_campaign(true)
	GameState.begin_chapter(self)
	menu.hide()
	stage = Stage.INTRO
	player.controls_enabled = false
	player.hide()
	cat.hide()
	var prologue_sari := _npc("Sari", SARI_IMAGE, SARI_REGION, 450.0)
	_start_dialogue(PROLOGUE, func() -> void:
		prologue_sari.queue_free()
		player.show()
		cat.show()
		start_chapter())

func _request_new_journey() -> void:
	if not GameState.has_save():
		_start_new_journey()
		return
	var box := _new_overlay("new_journey","Mulai dari awal?","Progres perjalanan yang tersimpan akan diganti. Demo baru mulai dengan 600 poin, semua atribut level 0, dan tiga hati.")
	_button(box,"Mulai baru",Rect2(40,330,380,58),func() -> void:
		_close_overlay()
		_start_new_journey())
	_button(box,"Batal",Rect2(440,330,380,58),_close_overlay,true)

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
		camera.position.x = lerpf(camera.position.x, clampf(player.position.x + 180,CAMERA_HALF_WIDTH,WORLD_WIDTH-CAMERA_HALF_WIDTH),1.0-exp(-delta*5))
	mountains.position.x = (camera.position.x-CAMERA_HALF_WIDTH)*0.65
	var cat_target := Vector2(player.position.x - player.facing * 66, player.position.y - 56.0)
	var cat_moving := absf(cat.position.x-cat_target.x)>12.0
	if cat_moving:
		cat.flip_h = cat_target.x < cat.position.x
		cat.position.x = move_toward(cat.position.x,cat_target.x,delta*235)
	cat.position.y = lerpf(cat.position.y, cat_target.y, 1.0 - exp(-delta * 7.0))
	_update_cat_animation(cat_moving, not player.is_on_floor())
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
		if overlay.visible and overlay_mode in ["pause","journal","about","upgrade"]:
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
	var path := "res://assets/Generated/Jaka/portrait.png"
	var region := Rect2(0,0,210,335)
	if line.speaker == "Sesepuh":
		path = "res://assets/Karakter/sesepuh.png"
		region = Rect2(264,102,499,1377)
	elif line.speaker == "Utusan":
		path = "res://assets/Karakter/NPC cwo.png"
		region = Rect2(253,150,483,1330)
	elif line.speaker == "Penjaga":
		path = "res://assets/Karakter/Penjaga Selarong.png"
		region = Rect2(0,0,1024,1536)
	elif line.speaker == "Sari":
		path = SARI_IMAGE
		region = SARI_REGION
	elif is_instance_valid(night_events) and str(line.speaker)==str(night_events.entry.get("speaker","")):
		path = night_events.entry.portrait
		var bounds: Array = night_events.entry.region
		region = Rect2(bounds[0],bounds[1],bounds[2],bounds[3])
	portrait.visible = line.speaker != "Narator"
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path)
	# A bust crop keeps the head and upper body large enough to read.
	if path != "res://assets/Generated/Jaka/portrait.png":
		region.size.y *= 0.48
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
	var card := _panel(choice_container,Rect2(705,390,547,105),Color("102826f2"),GOLD)
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
	if is_instance_valid(night_events): night_events.note_choice(choice)
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
	if health_icons.size()!=maximum and not health_icons.is_empty():
		var texture := health_icons[0].texture
		for icon in health_icons: icon.queue_free()
		health_icons.clear()
		for index in range(maximum):
			var icon := TextureRect.new()
			icon.texture = texture
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.position = Vector2(1040+index*34,65)
			icon.size = Vector2(30,28)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hud.add_child(icon)
			health_icons.append(icon)
	for index in range(health_icons.size()):
		health_icons[index].modulate = Color.WHITE if index < current else Color(0.25, 0.25, 0.25, 0.65)
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
	_paragraph(box,"A/D: jalan • Shift: dash lalu tahan untuk lari • Space: lompat\nKlik kiri: combo • Klik kanan: parry • S+Shift: dash mundur\nE: bicara • H: heal • L: ulti • T: catatan",Rect2(40,448,780,92),16,MUTED)

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
	if success: GameState.complete_chapter(1,self)
	hud.hide()
	var box := _new_overlay("result","Bab 1 selesai" if success else "Perjalanan belum berakhir", "Pesanmu sudah sampai. Perjalanan Jaka kini menuju jalur Selarong." if success else "Perjalanan Jaka terhenti sebelum keluar dari desa. Coba mulai kembali.")
	if success:
		_label(box,"TEGALREJO     - - - - - - - - - - - - >     SELARONG",Rect2(40,198,780,40),24,GOLD)
		_paragraph(box,"Juli 1825\nSetelah serangan di Tegalrejo, Diponegoro mundur ke Selarong dan menjadikannya basis awal perlawanan.",Rect2(40,270,780,100),23)
		_label(box,"Pesan tersampaikan    •    3 catatan sejarah ditemukan",Rect2(40,397,780,35),19,MUTED)
		_label(box,"Bab 2: Menembus Jalur Perlawanan sudah tersedia.",Rect2(40,441,780,30),17,MUTED)
	else:
		_paragraph(box,"Petunjuk\n\nTemui sesepuh, lalu utusan di tengah desa. Antarkan pesan kepada penjaga dekat gerbang sebelum berjalan ke kanan.",Rect2(40,210,780,220),23)
	if success:
		_button(box,"Lanjut Bab 2",Rect2(40,494,380,58),func() -> void: GameState.travel_to(2,self,false),true)
	else:
		_button(box,"Main lagi",Rect2(40,494,380,58),_restart,true)
	_button(box,"Menu utama",Rect2(440,494,380,58),_return_menu)

func _restart() -> void:
	GameState.start_on_load = true
	get_tree().paused = false
	get_tree().reload_current_scene()

func _return_menu() -> void:
	GameState.save_campaign(self)
	GameState.start_on_load = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://bab_tegalrejo.tscn")

extends Node
var chapter: Node2D
var hut: Node2D
var hint: Label
var points_label: Label
var near := false
var hut_x := 470.0
var soldiers: Array[Node] = []

func _ready() -> void:
	var file: String = chapter.get_script().resource_path.get_file()
	hut_x = 5650.0 if file=="chapter_two.gd" else (2780.0 if file=="chapter_three.gd" else 470.0)
	if chapter.get("hut_position")!=null: hut_x = float(chapter.get("hut_position"))
	hut = Node2D.new()
	hut.name = "UpgradeHut"
	hut.position = Vector2(hut_x,chapter.FLOOR_Y)
	chapter.world.add_child(hut)
	if file!="chapter_three.gd":
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/selarong_art.json")).shelter
		var region: Array = data.region
		var image := AtlasTexture.new()
		image.atlas = load(data.path)
		image.region = Rect2(region[0],region[1],region[2],region[3])
		var art := Sprite2D.new()
		art.texture = image
		art.scale = Vector2.ONE*210/image.region.size.y
		art.position.y = -105
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/prop_cutout.gdshader")
		art.material = material
		hut.add_child(art)
	chapter._label(hut,"GUBUK • UPGRADE",Rect2(-110,-244,220,30),17,chapter.GOLD)
	hint = chapter._label(chapter.hud,"[ E ]  Upgrade di gubuk",Rect2(390,574,500,40),20,chapter.GOLD)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.hide()
	chapter._panel(chapter.hud,Rect2(1024,220,228,32),Color("142b2ae8"),Color.TRANSPARENT)
	points_label = chapter._label(chapter.hud,"",Rect2(1032,224,220,24),14,chapter.GOLD)
	var positions: Array = [2450,2920,3400] if file=="chapter_one.gd" else ([4110,4470,4780] if file=="chapter_three.gd" else [])
	if chapter.get("optional_patrol_positions")!=null: positions = chapter.get("optional_patrol_positions")
	for x in positions: _soldier(float(x))

func _soldier(x: float) -> void:
	var enemy := preload("res://scripts/enemy.gd").new()
	enemy.position = Vector2(x,chapter.FLOOR_Y)
	enemy.target = chapter.player
	enemy.world_right = chapter.player.world_right
	enemy.defeated.connect(func(_enemy: Node) -> void: GameState.award_patrol_defeat())
	chapter.world.add_child(enemy)
	soldiers.append(enemy)

func _process(_delta: float) -> void:
	points_label.text = "POIN %d  •  MUSUH %d/3" % [GameState.upgrade_points,GameState.upgrade_defeats]
	near = chapter.player.controls_enabled and not GameState.dialogue_active and not chapter.paused and not chapter.overlay.visible and chapter.player.position.distance_to(hut.position)<145
	hint.visible = near

func _unhandled_input(event: InputEvent) -> void:
	if near and event.is_action_pressed("interact") and not event.is_echo():
		show_shop()
		get_viewport().set_input_as_handled()

func show_shop() -> void:
	chapter.paused = true
	get_tree().paused = true
	var box: Control = chapter._new_overlay("upgrade","Gubuk perjalanan","Tingkatkan atribut Jaka. Poin tersedia: %d" % GameState.upgrade_points)
	var labels := {"heart":"Hati maksimum","attack":"Daya serang","speed":"Kecepatan gerak","stamina":"Stamina maksimum"}
	var index := 0
	for attribute: String in labels:
		var cost := GameState.upgrade_cost(attribute)
		var text: String = "%s • Lv %d\n%s" % [labels[attribute],GameState.upgrade_levels[attribute],"MAKSIMUM" if cost<0 else "%d poin" % cost]
		var button: Button = chapter._button(box,text,Rect2(40+(index%2)*400,190+(index/2)*105,380,90),func() -> void:
			if GameState.buy_upgrade(attribute): show_shop())
		button.add_theme_font_size_override("font_size",18)
		button.disabled = cost<0 or GameState.upgrade_points<cost
		index += 1
	chapter._paragraph(box,"Setiap 3 tentara memberi 1 poin. Biaya naik dua kali lipat per level.\nHati awal 3; maksimum 6. Stamina pulih saat diam, jalan, dan lari.",Rect2(40,410,780,65),17,chapter.MUTED)
	chapter._button(box,"Kembali ke perjalanan",Rect2(40,490,780,58),chapter._close_overlay,true)

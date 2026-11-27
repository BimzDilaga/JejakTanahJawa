extends CanvasLayer
## An illustrated, skippable epilogue, followed by the full readable ending card.
var chapter: Node
var ending: Dictionary
var ending_id := ""
var art: TextureRect
var narration: RichTextLabel
var counter: Label
var next_button: Button
var sections: PackedStringArray
var index := 0
var typing := 0.0
var elapsed := 0.0
var score: AudioStreamPlayer

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var background := ColorRect.new()
	background.size = Vector2(1280,720)
	background.color = Color("102422")
	root.add_child(background)
	art = TextureRect.new()
	art.texture = load("res://assets/Generated/Endings/"+ending_id+"-v1.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.size = Vector2(1312,738)
	art.position = Vector2(-16,-9)
	root.add_child(art)
	var shade := ColorRect.new()
	shade.size = Vector2(1280,720)
	shade.color = Color(0.02,0.04,0.04,0.14)
	root.add_child(shade)
	chapter._panel(root,Rect2(28,26,750,76),Color("102522e8"),Color("b59d6a"))
	chapter._label(root,str(ending.title),Rect2(48,39,720,44),32,chapter.GOLD)
	chapter._button(root,"Lewati",Rect2(1090,35,150,44),finish).add_theme_font_size_override("font_size",17)
	var box: Control = chapter._panel(root,Rect2(28,492,1224,202),Color("102522f2"),Color("b59d6a"))
	narration = RichTextLabel.new()
	narration.position = Vector2(24,20)
	narration.size = Vector2(1176,116)
	narration.scroll_active = false
	narration.add_theme_font_size_override("normal_font_size",22)
	narration.add_theme_color_override("default_color",chapter.PAPER)
	box.add_child(narration)
	counter = chapter._label(box,"",Rect2(24,151,300,26),16,chapter.MUTED)
	next_button = chapter._button(box,"Berikutnya [E]",Rect2(858,143,342,43),advance,true)
	next_button.add_theme_font_size_override("font_size",17)
	sections = str(ending.text).split("\n\n",false)
	_show_section()
	score = AudioStreamPlayer.new()
	score.bus = "Music"
	score.stream = load("res://assets/Generated/Audio/Music/ending-memory.ogg")
	(score.stream as AudioStreamOggVorbis).loop = true
	score.volume_db = AudioPrefs.mix_db("ending_music_db",-6.0)
	add_child(score)
	if DisplayServer.get_name()!="headless": score.play()

func _process(delta: float) -> void:
	elapsed += delta
	typing += delta*45
	narration.visible_characters = int(typing)
	art.position.x = -16+sin(elapsed*0.07)*10

func _show_section() -> void:
	typing = 0
	narration.text = sections[index]
	narration.visible_characters = 0
	counter.text = "%02d / %02d  •  Epilog" % [index+1,sections.size()]
	next_button.text = "Selesai [E]" if index==sections.size()-1 else "Berikutnya [E]"

func advance() -> void:
	if narration.visible_characters<narration.get_total_character_count():
		typing = narration.get_total_character_count()
		narration.visible_characters = narration.get_total_character_count()
		return
	index += 1
	if index>=sections.size(): finish()
	else: _show_section()

func _input(event: InputEvent) -> void:
	if event.is_echo(): return
	if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		finish()
		get_viewport().set_input_as_handled()

func finish() -> void:
	if chapter.ending_director==self: chapter.ending_director = null
	queue_free()

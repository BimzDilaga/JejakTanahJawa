extends CanvasLayer
## Historical illustrations between the commander's defeat and the three endings.
signal finished
var chapter: Node
var content: Dictionary
var slides: Array
var index := 0
var typing := 0.0
var elapsed := 0.0
var active := true
var transitioning := false
var narration: RichTextLabel
var heading: Label
var counter: Label
var next_button: Button
var previous_button: Button
var skip_button: Button
var art: TextureRect
var old_art: TextureRect
var score: AudioStreamPlayer
var fade_tween: Tween
var _tree_was_paused := false
var _chapter_was_paused := false
var _ending_was_started := false
var _controls_were_enabled := false
var _previous_stage := 0

func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	content = JSON.parse_string(FileAccess.get_file_as_string("res://data/diponegoro_arrest.json"))
	slides = content.slides
	_tree_was_paused = get_tree().paused
	_chapter_was_paused = chapter.paused
	_ending_was_started = GameState.ending_started
	_controls_were_enabled = chapter.player.controls_enabled
	_previous_stage = int(chapter.stage)
	chapter.paused = true
	chapter.stage = chapter.Stage.TRANSITION
	chapter.player.controls_enabled = false
	GameState.ending_started = true
	get_tree().paused = true
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var background := ColorRect.new()
	background.size = Vector2(1280,720)
	background.color = Color("101b1d")
	root.add_child(background)
	old_art = _picture(root)
	art = _picture(root)
	chapter._panel(root,Rect2(28,26,810,82),Color("102522e8"),Color("b59d6a"))
	chapter._label(root,str(content.title),Rect2(48,35,765,36),27,chapter.GOLD)
	chapter._label(root,str(content.place_date),Rect2(48,75,765,24),16,chapter.PAPER)
	skip_button = chapter._button(root,"Lewati",Rect2(1090,30,162,48),finish)
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.add_theme_font_size_override("font_size",18)
	var box: Control = chapter._panel(root,Rect2(28,500,1224,194),Color("102522f2"),Color("b59d6a"))
	heading = chapter._label(box,"",Rect2(22,12,1178,29),23,chapter.GOLD)
	narration = RichTextLabel.new()
	narration.position = Vector2(22,49)
	narration.size = Vector2(1178,79)
	narration.scroll_active = false
	narration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	narration.add_theme_font_size_override("normal_font_size",21)
	narration.add_theme_color_override("default_color",chapter.PAPER)
	box.add_child(narration)
	previous_button = chapter._button(box,"< Sebelumnya",Rect2(22,142,198,40),previous)
	previous_button.focus_mode = Control.FOCUS_NONE
	previous_button.add_theme_font_size_override("font_size",17)
	counter = chapter._label(box,"",Rect2(240,146,640,30),15,chapter.MUTED)
	next_button = chapter._button(box,"Lanjut [E]",Rect2(940,142,260,40),advance)
	next_button.focus_mode = Control.FOCUS_NONE
	next_button.add_theme_font_size_override("font_size",17)
	score = AudioStreamPlayer.new()
	score.bus = "Music"
	score.stream = load(str(content.music))
	(score.stream as AudioStreamOggVorbis).loop = true
	score.volume_db = AudioPrefs.mix_db("history_music_db",-8.0)
	add_child(score)
	if DisplayServer.get_name()!="headless": score.play()
	_show_slide()

func _picture(parent: Control) -> TextureRect:
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.size = Vector2(1318,742)
	picture.position = Vector2(-19,-11)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture

func _process(delta: float) -> void:
	if not active: return
	elapsed += delta
	typing += delta*42.0
	narration.visible_characters = int(typing)
	art.position = Vector2(roundf(-19+sin(elapsed*0.06)*7),-11)

func _show_slide() -> void:
	if is_instance_valid(fade_tween): fade_tween.kill()
	old_art.texture = art.texture
	old_art.position = art.position
	old_art.modulate.a = 1.0
	art.texture = load(str(slides[index].image))
	art.modulate.a = 0.0
	heading.text = str(slides[index].heading)
	narration.text = str(slides[index].text)
	typing = 0
	narration.visible_characters = 0
	counter.text = "%02d / %02d  •  %s" % [index+1,slides.size(),str(content.note)]
	previous_button.disabled = index==0
	next_button.text = "Ke pilihan ending [E]" if index==slides.size()-1 else "Lanjut [E]"
	transitioning = true
	fade_tween = create_tween()
	fade_tween.tween_property(art,"modulate:a",1.0,0.45)
	fade_tween.tween_callback(func() -> void: transitioning = false)

func reveal() -> void:
	typing = float(narration.get_total_character_count())
	narration.visible_characters = int(typing)

func advance() -> void:
	if not active or transitioning: return
	if narration.visible_characters<narration.get_total_character_count():
		reveal()
		return
	if index==slides.size()-1:
		finish()
		return
	index += 1
	_show_slide()

func previous() -> void:
	if not active or transitioning or index==0: return
	index -= 1
	_show_slide()

func _input(event: InputEvent) -> void:
	if not active or event.is_echo(): return
	if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		finish()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("world_map") or event.is_action_pressed("journal"):
		get_viewport().set_input_as_handled()

func _restore_world() -> void:
	get_tree().paused = _tree_was_paused
	if is_instance_valid(chapter):
		chapter.paused = _chapter_was_paused
		chapter.stage = _previous_stage
		chapter.player.controls_enabled = _controls_were_enabled
	GameState.ending_started = _ending_was_started

func finish() -> void:
	if not active: return
	active = false
	if is_instance_valid(fade_tween): fade_tween.kill()
	score.stop()
	_restore_world()
	finished.emit()
	queue_free()

func _exit_tree() -> void:
	if active:
		active = false
		_restore_world()

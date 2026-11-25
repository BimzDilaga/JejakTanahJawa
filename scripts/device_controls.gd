extends CanvasLayer
## Multitouch gameplay controls and user-initiated fullscreen for desktop/web.
var chapter: Node
var touch_enabled := false
var pad: Node2D
var fullscreen_button: Button
var pause_button: Button
var next_button: Button
var buttons: Dictionary = {}

class PadButton extends TouchScreenButton:
	var caption := ""
	var radius := 42.0
	func _draw() -> void:
		var pressed := is_pressed()
		draw_circle(Vector2.ZERO,radius,Color(0.09,0.18,0.16,0.88 if pressed else 0.66))
		draw_arc(Vector2.ZERO,radius-1,0,TAU,40,Color("fff2d4") if pressed else Color("c9b888"),2,true)
		var font := ThemeDB.fallback_font
		var font_size := 15 if radius>30 else 12
		var width := font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		draw_string(font,Vector2(-width/2,5),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("fff2d4"))
	func _ready() -> void:
		pressed.connect(queue_redraw)
		released.connect(queue_redraw)

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	touch_enabled = DisplayServer.is_touchscreen_available() or OS.has_feature("android")
	if OS.has_feature("web"): touch_enabled = touch_enabled or bool(JavaScriptBridge.eval("navigator.maxTouchPoints > 0"))
	pad = Node2D.new()
	add_child(pad)
	_add("left","<",Vector2(75,625),"move_left")
	_add("right",">",Vector2(185,625),"move_right")
	_add("attack","Serang",Vector2(1065,515),"attack")
	_add("parry","Parry",Vector2(1065,620),"parry")
	_add("jump","Lompat",Vector2(1190,565),"jump",44)
	var dash := _add("dash","Dash/lari",Vector2(1190,450),"dash",38)
	dash.pressed.connect(func() -> void: Input.action_press("sprint"))
	dash.released.connect(func() -> void: Input.action_release("sprint"))
	var backward := _add("backdash","Mundur",Vector2(955,515),"",38)
	backward.pressed.connect(func() -> void: chapter.player.perform_dash(true))
	_add("interact","Bicara",Vector2(295,682),"interact",28)
	_add("heal","Heal",Vector2(415,682),"heal",28)
	_add("ultimate","Ulti",Vector2(525,682),"ultimate",28)
	_add("journal","Catatan",Vector2(635,682),"journal",28)
	fullscreen_button = chapter._button(self,"Layar penuh [F11]",Rect2(1030,675,222,34),toggle_fullscreen)
	fullscreen_button.add_theme_font_size_override("font_size",15)
	pause_button = chapter._button(self,"Jeda",Rect2(620,93,110,38),chapter._show_pause)
	next_button = chapter._button(self,"Lanjut >",Rect2(1110,674,142,34),chapter.advance_dialogue,true)
	_refresh()

func _add(id: String, caption: String, at: Vector2, action: String, radius := 42.0) -> PadButton:
	var button := PadButton.new()
	button.name = id
	button.caption = caption
	button.radius = radius
	button.position = at
	button.action = action
	button.passby_press = action in ["move_left","move_right"]
	var shape := CircleShape2D.new()
	shape.radius = radius
	button.shape = shape
	pad.add_child(button)
	buttons[id] = button
	return button

func _process(_delta: float) -> void: _refresh()

func _refresh() -> void:
	var modal: bool = chapter.overlay.visible or is_instance_valid(chapter.journey.map_layer) if is_instance_valid(chapter.journey) else chapter.overlay.visible
	var playing: bool = chapter.player.controls_enabled and not chapter.paused and not GameState.dialogue_active and not GameState.ending_started and not modal
	var show_pad: bool = touch_enabled and playing
	if pad.visible and not show_pad: _release()
	pad.visible = show_pad
	pause_button.visible = show_pad
	next_button.visible = touch_enabled and GameState.dialogue_active and not chapter.choice_active and not modal
	var in_menu: bool = chapter.menu.visible and not modal
	fullscreen_button.visible = in_menu or show_pad
	fullscreen_button.position = Vector2(745,93) if show_pad else Vector2(1030,675)
	fullscreen_button.text = "Layar penuh" if touch_enabled else "Layar penuh [F11]"
	if touch_enabled:
		for child in chapter.hud.get_children():
			if child is Label and child.text.begins_with("A/D"): child.hide()

func _release() -> void:
	for button: PadButton in buttons.values():
		if button.is_pressed() and not button.action.is_empty(): Input.action_release(button.action)
	Input.action_release("sprint")

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(pad): _release()

func _exit_tree() -> void:
	if is_instance_valid(pad): _release()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F11:
		toggle_fullscreen()
		get_viewport().set_input_as_handled()

func toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode in [DisplayServer.WINDOW_MODE_FULLSCREEN,DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN] else DisplayServer.WINDOW_MODE_FULLSCREEN)

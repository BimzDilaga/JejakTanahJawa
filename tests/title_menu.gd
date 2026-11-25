extends Node
var failures := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	preload("res://tests/test_session.gd").isolate("title_menu")
	var game: Node = load("res://bab_tegalrejo.tscn").instantiate()
	add_child(game)
	await frames(6)
	var picture: TextureRect = game.menu.get_node("GeneratedTitleArtwork")
	check(picture.texture.resource_path.ends_with("title-keyart-v1.png"),"Main menu uses the generated four-character artwork")
	check(picture.size==Vector2(1296,732),"All four characters and background legends stay inside the menu artwork framing: "+str(picture.size))
	var buttons: Array = game.menu.find_children("*","Button",true,false)
	check(buttons.size()==7 and buttons[0].disabled and buttons[1].has_focus(),"New player gets seven clean menu choices with new journey focused")
	game._show_boss_trials()
	check(game.overlay_mode=="boss_trials" and game.overlay_panel.find_children("*","Button",true,false).size()==5,"Four boss trials are accessible without covering title characters")
	game._close_overlay()
	game._show_settings()
	var sliders: Array = game.overlay_panel.find_children("*","HSlider",true,false)
	check(sliders.size()==4 and get_tree().paused,"Audio options expose four paused volume controls")
	sliders[1].value = 45
	sliders[2].value = 0
	await frames(30)
	check(is_equal_approx(float(AudioPrefs.levels.Music),0.45) and AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"Music and combat mix update live")
	var config := ConfigFile.new()
	check(config.load(AudioPrefs.settings_path)==OK and is_equal_approx(float(config.get_value("volume","Music")),0.45),"Audio choices persist to their own settings file")
	game._close_overlay()
	game.start_chapter()
	while GameState.dialogue_active: game.advance_dialogue()
	await frames(4)
	check(GameState.save_campaign(game),"A real journey enables continuation")
	var saved: String = FileAccess.get_file_as_string(GameState.save_path)
	game._set_menu()
	game._request_new_journey()
	check(game.overlay_mode=="new_journey","New journey asks before replacing an existing save")
	game._close_overlay()
	check(FileAccess.get_file_as_string(GameState.save_path)==saved,"Cancelling the new journey keeps the original save")
	GameState.reset_campaign()
	check(is_equal_approx(float(AudioPrefs.levels.Music),0.45),"Resetting campaign progress does not reset audio preferences")
	game.queue_free()
	await frames(3)
	print("TITLE_MENU failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

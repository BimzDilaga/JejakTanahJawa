extends Node
var failures := 0
var game: Node
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func dialogue() -> void:
	var safety := 0
	while GameState.dialogue_active and safety<100:
		game.advance_dialogue()
		safety += 1
	await frames(4)
	check(safety<100,"Story dialogue completes")
func _run() -> void:
	preload("res://tests/test_session.gd").isolate("late_chapters_endings.gd")
	GameState.reset_campaign()
	# Every chapter exposes a usable hut. Purchases persist across scene changes.
	for path in ["bab_tegalrejo","bab_jalur_perlawanan","bab_selarong","bab_desa_terdampak","bab_magelang"]:
		game = load("res://"+path+".tscn").instantiate()
		add_child(game)
		await frames(5)
		if path=="bab_tegalrejo": game.start_chapter()
		await dialogue()
		check(is_instance_valid(game.upgrade_hut) and is_instance_valid(game.upgrade_hut.hut),"Usable hut in "+path)
		game.upgrade_hut.show_shop()
		check(get_tree().paused and game.overlay_mode=="upgrade" and game.overlay.visible,"Hut opens a paused upgrade screen")
		var button: Button = game.overlay_panel.find_children("*","Button",true,false)[0]
		var old_health: int = game.player.max_health
		if path=="bab_tegalrejo":
			button.pressed.emit()
			check(game.player.max_health==old_health+1 and GameState.upgrade_points==598,"Shop button buys a real upgrade and refreshes the player")
		else: check(game.player.max_health==4 and GameState.upgrade_levels.heart==1,"Purchased health carries into "+path)
		game._close_overlay()
		check(not get_tree().paused,"Shop closes and resumes movement")
		game.queue_free()
		await frames(4)
	GameState.reset_campaign()
	game = load("res://bab_desa_terdampak.tscn").instantiate()
	add_child(game)
	await frames(5)
	await dialogue()
	for id in ["elder","family","report"]:
		game._interact(id)
		await dialogue()
	check(game.mission==3 and GameState.upgrade_defeats==0 and GameState.upgrade_points==600,"Chapter four story completes without defeating any patrol")
	game._interact("exit")
	check(game.stage==game.Stage.COMPLETE and game.overlay.visible,"Chapter four opens its continuation screen")
	var next_button: Button = game.overlay_panel.find_children("*","Button",true,false)[0]
	check(next_button.text.contains("Bab 5"),"Chapter four explicitly continues to Magelang")
	game.queue_free()
	await frames(4)
	game = load("res://bab_magelang.tscn").instantiate()
	add_child(game)
	await frames(5)
	await dialogue()
	game._interact("guide")
	await dialogue()
	check(game.mission==1 and GameState.upgrade_defeats==0,"Chapter five reaches the commander without patrol kills")
	game._interact("commander")
	await dialogue()
	var arena: Node = get_tree().current_scene
	check(arena.scene_file_path=="res://boss_trial.tscn" and arena.kind=="commander" and not game.is_inside_tree(),"Story opens the human final boss and holds Magelang")
	await frames(70)
	arena.boss.take_damage(999,0)
	check(not GameState.night_boss_defeated.get("commander",false),"First commander bar cannot unlock an ending")
	await frames(240)
	arena.boss.take_damage(999,0)
	await frames(80)
	check(GameState.night_boss_defeated.get("commander",false),"Final commander victory is recorded")
	arena._return_menu()
	await frames(5)
	check(game.is_inside_tree() and game.mission==3,"Commander victory resumes the same Magelang journey")
	await dialogue()
	check(game.overlay_mode=="ending_choice" and game.stage==game.Stage.COMPLETE,"Epilogue presents the ending choice")
	var choices: Array = game.overlay_panel.find_children("*","Button",true,false)
	check(choices.size()==4 and choices[2].disabled and not GameState.secret_ending_ready(),"Secret ending stays locked and the player can return to the map")
	for id in ["pulang","bertahan"]:
		game._show_ending(id)
		check(GameState.unlocked_endings.get(id,false) and game.overlay_mode=="ending","Regular ending can be selected: "+id)
	GameState.night_boss_defeated.buto = true
	GameState.night_boss_defeated.banaspati = true
	check(not GameState.secret_ending_ready(),"Two urban bosses are insufficient")
	GameState.night_boss_defeated.headless = true
	check(GameState.secret_ending_ready(),"All three urban bosses plus commander unlock the secret ending")
	game._ending_choice()
	choices = game.overlay_panel.find_children("*","Button",true,false)
	check(not choices[2].disabled,"Secret choice becomes selectable")
	choices[2].pressed.emit()
	check(GameState.unlocked_endings.size()==3,"All three distinct ending records are reachable")
	var endings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/endings.json"))
	check(endings.size()==3 and endings.jejak.text!=endings.pulang.text and endings.pulang.text!=endings.bertahan.text,"Three endings retain distinct story text")
	get_tree().current_scene = null
	game.queue_free()
	await frames(4)
	GameState.reset_campaign()
	check(GameState.upgrade_points==600 and GameState.player_max_health()==3 and GameState.unlocked_endings.is_empty() and GameState.night_boss_defeated.is_empty(),"New journey resets demo progress to zero levels and 600 points")
	print("LATE_CHAPTERS_ENDINGS failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

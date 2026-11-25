extends Node
var failures := 0
var game: Node
var capture_dir := ""

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="): capture_dir = arg.trim_prefix("--screenshots=")
	if not capture_dir.is_empty(): DirAccess.make_dir_recursive_absolute(capture_dir)
	_run.call_deferred()

func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func dialogue(choice := 0) -> void:
	var safety := 0
	while GameState.dialogue_active and safety<80:
		if game.choice_active: game._choose(choice)
		else: game.advance_dialogue()
		safety += 1
	await frames(4)
	check(safety<80,"Dialogue completes")

func shot(name: String) -> void:
	if capture_dir.is_empty(): return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir.path_join(name+".png"))

func press_interact() -> void:
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventAction.new()
	event.action = "interact"
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)

func _run() -> void:
	preload("res://tests/test_session.gd").isolate("night_encounters.gd")
	GameState.reset_campaign()
	GameState.upgrade_levels.heart = 2
	for path in ["res://bab_tegalrejo.tscn","res://bab_jalur_perlawanan.tscn","res://bab_desa_terdampak.tscn"]:
		game = load(path).instantiate()
		add_child(game)
		await frames(5)
		if path.ends_with("bab_tegalrejo.tscn"): game.start_chapter()
		await dialogue()
		game.notice_time = 0
		game.notice.hide()
		if path.ends_with("bab_jalur_perlawanan.tscn"):
			game.mission = 2
			GameState.set_objective("Cari warga yang membutuhkan bantuan di hutan.")
		game.day_night.clock_enabled = false
		var events: Node = game.night_events
		check(is_instance_valid(events.witness),"Chapter has a stationary rumor witness")
		GameState.time_of_day = 0.375
		await frames(3)
		check(not events.witness.visible,"Witness does not crowd daytime locations")
		GameState.time_of_day = 0.875
		game.player.position = events.witness.position+Vector2(-70,0)
		game.camera.position.x = maxf(game.CAMERA_HALF_WIDTH,game.player.position.x+150)
		await frames(5)
		check(events.witness.visible and events.near,"Night reveals witness at a safe village/camp location")
		check(not events.clue.visible,"An unheard rumor cannot open the boss route")
		await shot("night-witness-"+str(events.entry.kind))
		await press_interact()
		check(GameState.dialogue_active and game.speaker_label.text==events.entry.speaker,"E reaches the rumor before chapter interaction")
		await dialogue(1)
		check(game.is_inside_tree() and not is_instance_valid(GameState.encounter_chapter),"Declining keeps the journey in place")
		var expected_stage: int = game.stage
		GameState.set_objective("Tujuan perjalanan yang harus dipulihkan")
		GameState.heal_stock = 2
		GameState.defeats_toward_heal = 4
		game.player.health = 4
		var position_before: Vector2 = game.player.position
		events.talk()
		await dialogue(0)
		check(game.is_inside_tree() and events.rumor_learned,"Accepting a rumor unlocks investigation without teleporting")
		game.player.position = events.clue.position+Vector2(-45,0)
		await frames(4)
		check(events.clue.visible and events.near_clue,"The clue can be inspected only after learning the rumor")
		events.investigate()
		await dialogue(1)
		check(game.is_inside_tree(),"Declining the clue preserves the journey")
		position_before = game.player.position
		events.investigate()
		await dialogue(0)
		var arena: Node = get_tree().current_scene
		check(is_instance_valid(arena) and arena.scene_file_path=="res://boss_trial.tscn","Accepting opens the corresponding boss encounter")
		check(not game.is_inside_tree() and arena.kind==events.entry.kind,"Story node is held while the right boss loads")
		await frames(70)
		arena.boss.take_damage(999,arena.player.position.x)
		if arena.boss.in_phase_transition():
			check(not GameState.night_boss_defeated.get(events.entry.kind,false),"Phase one does not satisfy an ending requirement")
			await frames(240)
			arena.boss.take_damage(999,arena.player.position.x)
		await frames(3)
		check(GameState.night_boss_defeated.get(events.entry.kind,false),"A story encounter records its boss victory")
		arena._return_menu()
		await frames(5)
		check(game.is_inside_tree() and get_tree().current_scene==game,"Return resumes the same story scene")
		check(game.stage==expected_stage and game.player.health==4,"Chapter progression and story health survive the encounter")
		check(game.player.position.distance_to(position_before)<2,"Return preserves the investigated clue position")
		check(GameState.objective=="Tujuan perjalanan yang harus dipulihkan" and GameState.heal_stock==2 and GameState.defeats_toward_heal==4,"Objective and supplies restore without trial rewards leaking")
		game.player.position = events.witness.position+Vector2(-70,0)
		await frames(3)
		events.talk()
		await dialogue()
		check(game.is_inside_tree() and not is_instance_valid(GameState.encounter_chapter),"Defeated boss has aftermath dialogue")
		GameState.time_of_day = 0.125
		await frames(3)
		check(not events.witness.visible,"Witness leaves at dawn")
		get_tree().current_scene = null
		game.queue_free()
		await frames(4)
	GameState.reset_campaign()
	check(GameState.night_boss_defeated.is_empty(),"New journey clears night victories")
	print("NIGHT_ENCOUNTERS failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

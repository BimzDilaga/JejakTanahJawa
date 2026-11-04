extends Node
var failures: int = 0
var game: Node
var snapshots: bool = false
var capture_dir: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			capture_dir = arg.trim_prefix("--screenshots=")
			snapshots = true
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("CHECK FAILED: " + message)

func frames(count: int = 3) -> void:
	for i in range(count):
		await get_tree().physics_frame

func shot(name: String) -> void:
	if snapshots:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture_dir.path_join(name+".png"))

func finish_dialogue() -> void:
	var guard: int = 0
	while GameState.dialogue_active and guard < 60:
		game.advance_dialogue()
		guard += 1
	check(guard < 60,"Dialog chain must terminate")
	await frames()

func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)

func _run() -> void:
	game = load("res://bab_tegalrejo.tscn").instantiate()
	add_child(game)
	await frames(8)
	check(game.stage == game.Stage.MENU,"Starts at menu")
	check(game.player.is_on_floor(),"Player starts on floor")
	await shot("01-menu")
	game.start_chapter()
	await frames()
	var before: Vector2 = game.player.position
	Input.action_press("move_right")
	await frames(12)
	Input.action_release("move_right")
	check(absf(game.player.position.x-before.x)<1,"Dialogue locks movement")
	await finish_dialogue()
	check(game.stage == game.Stage.EXPLORE,"Intro enters exploration")
	Input.action_press("move_right")
	await frames(12)
	Input.action_release("move_right")
	check(game.player.position.x>before.x+25,"Real input moves player")
	await press("jump")
	check(game.player.position.y<555,"Jump leaves floor")
	await frames(65)
	check(game.player.is_on_floor(),"Jump lands safely")
	game.player.position = Vector2(3550,570)
	await frames(5)
	check(game.stage==game.Stage.EXPLORE,"Premature exit cannot complete chapter")
	game.player.position = Vector2(820,570)
	await frames(45)
	check(game.sari_area.player_near,"NPC proximity detects player")
	await shot("02-village")
	await press("interact")
	check(GameState.dialogue_active,"E opens Sari dialogue")
	game.advance_dialogue()
	await shot("03-dialogue")
	await finish_dialogue()
	check(game.stage==game.Stage.BATTLE,"Sari and warning start battle")
	check(get_tree().get_nodes_in_group("enemies").size()==2,"Exactly two enemies spawn")
	check(game.facts_unlocked==2,"First two facts unlocked")
	await shot("04-battle")
	game._show_pause()
	check(get_tree().paused,"Pause pauses world")
	var old_pos: Vector2 = game.player.position
	Input.action_press("move_right")
	await frames(8)
	Input.action_release("move_right")
	check(game.player.position==old_pos,"Paused player remains stationary")
	game._close_overlay()
	check(not get_tree().paused,"Resume unpauses")
	# Prove enemy attack connects after its readable windup.
	var first: Node = get_tree().get_nodes_in_group("enemies")[0]
	game.player.position = first.position-Vector2(60,0)
	var previous_hp: int = game.player.health
	await frames(95)
	check(game.player.health<previous_hp,"Enemy deals damage after telegraph")
	game.player.reset_health()
	# Defeat both through the actual player attack timer/hit dispatch.
	for enemy: Node in get_tree().get_nodes_in_group("enemies").duplicate():
		for hit in range(3):
			if not is_instance_valid(enemy):
				break
			game.player.position = enemy.position-Vector2(120,0)
			game.player.facing = 1
			game.player.perform_attack()
			await frames(34)
	check(GameState.enemies_defeated==2,"Counter increments once per defeated enemy")
	check(get_tree().get_nodes_in_group("enemies").is_empty(),"Both enemies removed")
	await finish_dialogue()
	check(game.stage==game.Stage.EXIT,"Post-battle dialogue opens exit")
	check(GameState.objective_completed,"Exit objective completed")
	game._show_journal()
	await shot("05-journal")
	game._close_overlay()
	game.player.position = Vector2(3550,570)
	await frames(7)
	check(game.stage==game.Stage.TRANSITION,"Exit triggers transition")
	await finish_dialogue()
	check(game.stage==game.Stage.COMPLETE,"Chapter completes")
	check(not game.player.controls_enabled,"Ending locks player")
	await shot("06-complete")
	game.queue_free()
	await frames(4)
	game = load("res://bab_tegalrejo.tscn").instantiate()
	add_child(game)
	await frames(4)
	check(not GameState.ending_started and GameState.enemies_defeated==0,"Fresh run resets state")
	game.start_chapter()
	await finish_dialogue()
	game.player.take_damage(5,game.player.position.x-1)
	await frames()
	check(game.stage==game.Stage.FAILED,"Death shows retry panel")
	await shot("07-retry")
	print("CHAPTER_SMOKE failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

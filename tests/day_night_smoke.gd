extends Node
const Cycle = preload("res://scripts/day_night_cycle.gd")
var failures := 0
var game: Node
var capture_dir := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--screenshots="):
			capture_dir = argument.trim_prefix("--screenshots=")
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame

func finish_dialogue() -> void:
	var limit := 0
	while GameState.dialogue_active and limit < 80:
		game.advance_dialogue()
		limit += 1
	check(limit < 80,"Dialogue finishes")
	await frames(3)

func _capture_phases(chapter: int) -> void:
	if capture_dir.is_empty():
		return
	game.player.controls_enabled = false
	await frames(60)
	for phase in range(4):
		GameState.time_of_day = phase * 0.25 + 0.125
		game.day_night.apply_time()
		await frames(3)
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		check(image.save_png(capture_dir.path_join("chapter-%d-%s.png" % [chapter,Cycle.PHASE_NAMES[phase].to_lower()])) == OK,"Save time-of-day screenshot")
	game.player.controls_enabled = true

func _run() -> void:
	preload("res://tests/test_session.gd").isolate("day_night_smoke.gd")
	GameState.reset_campaign()
	check(is_equal_approx(GameState.day_cycle_seconds,420.0),"The cycle retains one-minute morning/evening and 150-second noon/night")
	for phase in range(4):
		var expected: float = 150.0 if phase in [1,3] else 60.0
		check(is_equal_approx(GameState.day_phase_duration(phase),expected),"Configured duration for "+Cycle.PHASE_NAMES[phase])
		GameState.time_of_day = phase*0.25
		GameState.advance_day_time(expected-1.0)
		check(Cycle.phase_index(GameState.time_of_day)==phase,"Phase remains active until its final second: "+Cycle.PHASE_NAMES[phase])
		GameState.advance_day_time(1.0)
		check(is_equal_approx(GameState.time_of_day,fposmod((phase+1)*0.25,1.0)),"Phase advances at exactly its configured duration: "+Cycle.PHASE_NAMES[phase]+" "+str(GameState.time_of_day))
	GameState.time_of_day = 0.625
	GameState.advance_day_time(840.0)
	check(is_equal_approx(GameState.time_of_day,0.625),"Advancing two complete cycles preserves the phase")
	GameState.reset_campaign()
	game = load("res://bab_tegalrejo.tscn").instantiate()
	add_child(game)
	await frames(6)
	check(Cycle.phase_name(GameState.time_of_day)=="Sore","Start in the afternoon matching the prologue")
	var before: float = GameState.time_of_day
	await frames(10)
	check(is_equal_approx(GameState.time_of_day,before),"Menu freezes the clock")
	check(game.day_night.layer==5 and game.ui.get_canvas_layer_node().layer==10,"World grading sits below UI")
	check(game.day_night.filter_rect.size==get_viewport().get_visible_rect().size,"Filter covers the viewport")
	game.start_chapter()
	await frames(6)
	check(is_equal_approx(GameState.time_of_day,before),"Dialogue freezes the clock")
	await finish_dialogue()
	before = GameState.time_of_day
	await frames(60)
	check(GameState.time_of_day>before and GameState.time_of_day-before<0.01,"Clock advances during exploration at the configured speed")
	game._show_pause()
	before = GameState.time_of_day
	await frames(10)
	check(is_equal_approx(GameState.time_of_day,before),"Pause freezes the clock")
	game._close_overlay()
	GameState.ending_started = true
	before = GameState.time_of_day
	await frames(6)
	check(is_equal_approx(GameState.time_of_day,before),"Endings freeze the clock")
	GameState.ending_started = false
	game.player.dead = true
	await frames(6)
	check(is_equal_approx(GameState.time_of_day,before),"Death freezes the clock")
	game.player.dead = false
	game.player.controls_enabled = false
	GameState.time_of_day = 0.9
	GameState.advance_day_time(84.0)
	check(is_equal_approx(GameState.time_of_day,0.1),"Cycle wraps from night into morning")
	var left: Dictionary = Cycle.sample_grade(0.999999)
	var right: Dictionary = Cycle.sample_grade(0.000001)
	check(absf(left.exposure-right.exposure)<0.0001 and (left.tint as Color).is_equal_approx(right.tint),"Grading remains continuous across the cycle boundary")
	for phase in range(4):
		GameState.time_of_day = phase * 0.25 + 0.125
		await frames(2)
		check(game.time_label.text==Cycle.PHASE_NAMES[phase].to_upper(),"HUD follows phase " + Cycle.PHASE_NAMES[phase])
	check(Cycle.sample_grade(0.875).exposure<Cycle.sample_grade(0.375).exposure,"Night is darker than noon")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_F6
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	check(Cycle.phase_name(GameState.time_of_day)=="Pagi","Debug F6 previews the next phase")
	event = InputEventKey.new()
	event.physical_keycode = KEY_F6
	event.pressed = false
	Input.parse_input_event(event)
	await _capture_phases(1)
	game.queue_free()
	await frames(3)
	var scene_paths := ["res://bab_jalur_perlawanan.tscn","res://bab_selarong.tscn"]
	for index in range(scene_paths.size()):
		GameState.time_of_day = 0.875
		game = load(scene_paths[index]).instantiate()
		add_child(game)
		await frames(4)
		check(is_equal_approx(GameState.time_of_day,0.875),"Chapter transition preserves time in chapter %d" % [index+2])
		check(game.time_label.text=="MALAM" and game.day_night.filter_rect.visible,"Night filter is active in chapter %d" % [index+2])
		await finish_dialogue()
		await _capture_phases(index+2)
		game.player.controls_enabled = false
		game.queue_free()
		await frames(3)
	GameState.reset_campaign()
	check(is_equal_approx(GameState.time_of_day,GameState.DAY_START),"New journey resets to its initial time")
	print("DAY_NIGHT_SMOKE failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

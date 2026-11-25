extends Node
var capture_dir := ""
var game: Node

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--screenshots="):
			capture_dir = argument.trim_prefix("--screenshots=")
	_run.call_deferred()

func frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(capture_dir.path_join(label + ".png")) == OK)

func _run() -> void:
	preload("res://tests/test_session.gd").isolate("jaka_visual_review.gd")
	assert(not capture_dir.is_empty(), "Supply --screenshots=<directory> with a rendering display driver")
	game = load("res://bab_jalur_perlawanan.tscn").instantiate()
	add_child(game)
	await frames(6)
	while GameState.dialogue_active:
		game.advance_dialogue()
	game.player.position = Vector2(1100,570)
	await frames(40)
	await shot("01-idle")
	Input.action_press("move_right")
	await frames(9)
	await shot("02-walk")
	Input.action_press("sprint")
	await frames(10)
	await shot("03-run")
	Input.action_release("sprint")
	Input.action_release("move_right")
	game.player.perform_parry()
	await frames(8)
	await shot("04-parry-window")
	game.player.take_damage(1,game.player.position.x+30,true)
	await frames(7)
	await shot("05-parry-success")
	for i in range(4):
		game.player.perform_parry()
		game.player.take_damage(1,game.player.position.x+30,true)
	game.player.perform_parry()
	await frames(8)
	await shot("06-stance-break")
	game.player.reset_health()
	game.player.health = 4
	GameState.heal_stock = 1
	game.player.perform_heal()
	await frames(23)
	await shot("07-heal")
	game.player.reset_health()
	game.player.ultimate_charge = game.player.ULTIMATE_HITS
	game.player.perform_ultimate()
	await frames(17)
	await shot("08-ultimate")
	game.player.reset_health()
	game._start_dialogue([{"speaker":"Jaka", "text":"Aku harus menjaga keseimbangan. Tangkisan berikutnya bisa membuatku terbuka."}], Callable())
	await frames(5)
	await shot("09-dialogue")
	print("JAKA_VISUAL_REVIEW complete")
	get_tree().quit()

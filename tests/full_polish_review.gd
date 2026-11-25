extends Node
var directory := "res://.godot/full-polish-review"
var game: Node
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame
func dialogue() -> void:
	while GameState.dialogue_active: game.advance_dialogue()
	await frames(3)
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(directory.path_join(name+".png"))==OK)
func _run() -> void:
	preload("res://tests/test_session.gd").isolate("full_polish_review")
	DirAccess.make_dir_recursive_absolute(directory)
	game = load("res://bab_tegalrejo.tscn").instantiate()
	add_child(game)
	await frames(8)
	await shot("menu-new")
	game.start_chapter()
	await dialogue()
	GameState.unlocked_chapter = 2
	GameState.completed_chapters = [1]
	game.journey.show_map()
	await frames(4)
	await shot("map-locked")
	game.journey.close_map()
	GameState.unlocked_chapter = 5
	GameState.completed_chapters = [1,2,3,4]
	GameState.night_boss_defeated = {"buto":true,"banaspati":true}
	game.journey.show_map()
	await frames(4)
	await shot("map-open")
	game.journey.close_map()
	game.player.position = Vector2(500,570)
	game.player.ultimate_charge = 5
	game.player.perform_ultimate()
	await frames(12)
	await shot("ultimate-clean")
	game.queue_free()
	await frames(4)
	GameState.boss_trial_kind = "headless"
	game = load("res://boss_trial.tscn").instantiate()
	add_child(game)
	await frames(70)
	game.boss.set_physics_process(false)
	game.player.controls_enabled = false
	game.player.position = Vector2(500,570)
	game.boss.position = Vector2(800,570)
	for animation in ["spawn","backhand","low_spin","vanish","leap_slam","ultimate"]:
		game.boss._pose(animation,0.7)
		await frames(3)
		await shot("headless-"+animation)
	game.queue_free()
	await frames(4)
	game = load("res://bab_magelang.tscn").instantiate()
	add_child(game)
	await frames(6)
	await dialogue()
	game.stage = game.Stage.COMPLETE
	GameState.ending_started = true
	GameState.night_boss_defeated = {"buto":true,"banaspati":true,"headless":true,"commander":true}
	for id in ["pulang","bertahan","jejak"]:
		game._show_ending(id)
		await frames(4)
		game.ending_director.typing = 1000
		await frames(2)
		await shot("ending-"+id)
		game.ending_director.finish()
		await frames(3)
		await shot("ending-card-"+id)
	game.queue_free()
	await frames(4)
	var contact := Image.create(224*8,144,false,Image.FORMAT_RGBA8)
	contact.fill(Color("66796d"))
	for index in range(8):
		var image: Image = (load("res://assets/Generated/Jaka/ultimate_clean_%02d.png" % [index+1]) as Texture2D).get_image()
		contact.blend_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),Vector2i(index*224,0))
	contact.save_png(directory.path_join("ultimate-frames.png"))
	print("FULL_POLISH_REVIEW complete")
	get_tree().quit()

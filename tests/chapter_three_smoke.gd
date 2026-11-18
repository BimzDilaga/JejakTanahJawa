extends Node
var game: Node
var failures := 0
var capture_dir := ""

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			capture_dir=arg.trim_prefix("--screenshots=")
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures+=1
		push_error(message)

func frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame

func dialogue() -> void:
	var safety := 0
	while GameState.dialogue_active and safety<80:
		if game.choice_active:
			game._choose(0)
		else:
			game.advance_dialogue()
		safety+=1
	await frames(3)
	check(safety<80,"Dialogue completed")

func walk(target: float) -> void:
	var action := "move_right" if target>game.player.position.x else "move_left"
	Input.action_press(action)
	var ticks := 0
	while absf(game.player.position.x-target)>9 and ticks<600:
		await frames(1)
		ticks+=1
	Input.action_release(action)
	await frames(2)
	check(ticks<600,"Reach x="+str(target))

func hop(target: float) -> void:
	Input.action_press("jump")
	await frames(1)
	Input.action_release("jump")
	await walk(target)
	await frames(32)
	check(game.player.is_on_floor(),"Land at x="+str(target))

func shot(name: String) -> void:
	if capture_dir!="":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture_dir.path_join(name+".png"))

func _run() -> void:
	game=load("res://bab_selarong.tscn").instantiate()
	add_child(game)
	await frames(6)
	await dialogue()
	check(game.stage==game.Stage.EXPLORE,"Chapter starts in exploration")
	check(game.player.world_right>4900,"Selarong extends to the lookout")
	check(game.story.has("prince") and game.story.has("report"),"Chapter 3 story loaded")
	check(game.world.find_children("WargaBerjalan*","",true,false).is_empty(),"No wandering village NPC in Selarong")
	await shot("selarong-start")
	Input.action_press("sprint")
	await walk(1250)
	await hop(1380)
	await walk(1400)
	await hop(1550)
	await walk(1590)
	await hop(1730)
	await walk(2140)
	game._interact("guard")
	await dialogue()
	check(game.mission==1 and game.facts_unlocked==1,"Guard receives the message")
	await shot("selarong-guard")
	await walk(3540)
	game._interact("prince")
	await dialogue()
	check(game.mission==2 and game.facts_unlocked==2,"Diponegoro requests observation")
	check(game.portrait.texture.atlas.resource_path=="res://assets/Karakter/Pangeran Diponegoro.png","Diponegoro portrait uses the supplied asset")
	await shot("selarong-cave")
	await walk(4300)
	await hop(4440)
	game._interact("lookout")
	await dialogue()
	check(game.mission==3,"Lookout sends Jaka back")
	await shot("selarong-lookout")
	await walk(3540)
	game._interact("prince")
	await dialogue()
	check(game.stage==game.Stage.COMPLETE and game.facts_unlocked==3,"Report finishes Chapter 3")
	check(game.overlay.visible,"Completion card visible")
	await shot("selarong-ending")
	Input.action_release("sprint")
	print("CHAPTER_THREE_SMOKE failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

extends Node
var directory := ""
var game: Node
func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="): directory = arg.trim_prefix("--screenshots=")
	_run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(name+".png"))
func _run() -> void:
	preload("res://tests/test_session.gd").isolate("combat_polish_review.gd")
	assert(not directory.is_empty())
	DirAccess.make_dir_recursive_absolute(directory)
	# A contact sheet reveals cutting errors, dirty alpha and inconsistent scale.
	var atlas := Image.create(224*6,144*9,false,Image.FORMAT_RGBA8)
	atlas.fill(Color("66796d"))
	var prefixes := ["attack","chain_2","chain_3","jump","reaction_1","reaction_2","dash","backdash","idle"]
	for row in range(prefixes.size()):
		for col in range(1 if prefixes[row]=="idle" else 6):
			var image: Image = (load("res://assets/Generated/Jaka/%s_%02d.png" % [prefixes[row],col+1]) as Texture2D).get_image()
			atlas.blend_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),Vector2i(col*224,row*144))
	assert(atlas.save_png(directory.path_join("jaka-frames.png"))==OK)
	var boss_atlas := Image.create(448*6,320*3,false,Image.FORMAT_RGBA8)
	boss_atlas.fill(Color("66796d"))
	for row in range(3):
		for col in range(6):
			var image: Image = (load("res://assets/Generated/Bosses/buto_%s_%02d.png" % [["spawn","stagger","death"][row],col+1]) as Texture2D).get_image()
			boss_atlas.blend_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),Vector2i(col*448,row*320))
	assert(boss_atlas.save_png(directory.path_join("buto-frames.png"))==OK)
	GameState.boss_trial_kind = "buto"
	game = load("res://boss_trial.tscn").instantiate()
	add_child(game)
	await frames(70)
	game.boss.set_physics_process(false)
	game.player.position = Vector2(500,570)
	game.boss.position = Vector2(750,570)
	game.player.perform_attack()
	await frames(10)
	game.player.perform_attack()
	await frames(24)
	await shot("combo-second")
	game.player.perform_attack()
	await frames(25)
	await shot("combo-finisher")
	game.player.reset_health()
	game.player.perform_dash()
	await frames(5)
	await shot("dash-forward")
	game.player.reset_health()
	game.player.perform_dash(true)
	await frames(5)
	await shot("dash-backward")
	game.player.reset_health()
	game.boss._pose("stagger",1)
	await frames(2)
	await shot("buto-kneeling")
	game.boss._pose("death",1)
	await frames(2)
	await shot("buto-fallen")
	game.player.take_damage(99,game.player.position.x+20)
	await frames(60)
	await shot("jaka-defeat")
	print("COMBAT_POLISH_REVIEW complete")
	get_tree().quit()

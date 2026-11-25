extends Node
var directory := "res://.godot/late-review"
var game: Node
func _ready() -> void: _run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(name+".png"))
func _run() -> void:
	preload("res://tests/test_session.gd").isolate("late_visual_review.gd")
	DirAccess.make_dir_recursive_absolute(directory)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/boss_assets.json"))
	for kind in ["commander","headless"]:
		var animations := ["idle","walk","light","heavy","stagger","death","reload"] if kind=="commander" else ["idle","walk","light","heavy","stagger","death"]
		var atlas := Image.create(448*6,320*animations.size(),false,Image.FORMAT_RGBA8)
		atlas.fill(Color("66796d"))
		for row in range(animations.size()):
			var files: Array = manifest[kind][animations[row]].files
			for col in range(mini(6,files.size())):
				var file: String = files[roundi(float(col)*(files.size()-1)/5)]
				var image: Image = (load(file) as Texture2D).get_image()
				atlas.blend_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),Vector2i(col*448,row*320))
		atlas.save_png(directory.path_join(kind+"-frames.png"))
	GameState.reset_campaign()
	for chapter in ["bab_desa_terdampak","bab_magelang"]:
		game = load("res://"+chapter+".tscn").instantiate()
		add_child(game)
		await frames(6)
		while GameState.dialogue_active: game.advance_dialogue()
		game.player.set_physics_process(false)
		game.player.controls_enabled = false
		game.day_night.clock_enabled = false
		game.notice_time = 0
		game.notice.hide()
		for time in [0.375,0.875]:
			GameState.time_of_day = time
			for x in [550,2500,4800,5900]:
				game.player.position.x = x
				game.camera.position.x = clampf(x+150,game.CAMERA_HALF_WIDTH,game.length-game.CAMERA_HALF_WIDTH)
				game.camera.force_update_scroll()
				await frames(4)
				await shot("%s-%s-%d" % [chapter,"day" if time<0.5 else "night",x])
		game.player.controls_enabled = true
		game.upgrade_hut.show_shop()
		await frames(3)
		await shot(chapter+"-shop")
		game._close_overlay()
		game.queue_free()
		await frames(4)
	for kind in ["commander","headless","banaspati"]:
		GameState.boss_trial_kind = kind
		game = load("res://boss_trial.tscn").instantiate()
		add_child(game)
		await frames(70)
		game.boss.set_physics_process(false)
		game.player.position = Vector2(500,570)
		game.boss.position = Vector2(800,570)
		await frames(10)
		await shot(kind+"-arena")
		game.boss._pose("stagger",1)
		await frames(3)
		await shot(kind+"-stagger")
		game.boss._pose("death",1)
		await frames(3)
		await shot(kind+"-fall")
		game.queue_free()
		await frames(4)
	print("LATE_VISUAL_REVIEW complete")
	get_tree().quit()

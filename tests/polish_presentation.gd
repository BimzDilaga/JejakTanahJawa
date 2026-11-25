extends Node
var failures := 0
var game: Node
func _ready() -> void: _run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	preload("res://tests/test_session.gd").isolate("polish_presentation")
	game = load("res://bab_magelang.tscn").instantiate()
	add_child(game)
	await frames(6)
	while GameState.dialogue_active: game.advance_dialogue()
	var ultimate: SpriteFrames = game.player.anim.sprite_frames
	for index in range(8):
		var texture: Texture2D = ultimate.get_frame_texture("ultimate",index)
		check(texture.resource_path.contains("ultimate_clean"),"Ultimate uses the transparent replacement")
		var image := texture.get_image()
		check(image.get_pixel(0,0).a==0 and image.get_used_rect().end.y==144,"Clean ultimate keeps alpha and the same grounded baseline")
		for y in range(0,144,8):
			for x in range(0,224,8): check(image.get_pixel(x,y).a in [0.0,1.0],"No dark semitransparent matte survives in the ultimate")
	check(game.world_audio.night.stream.loop and game.world_audio.night.stream.get_length()>20 and game.world_audio.wind.stream.loop,"Environment ambience is decoded and looped")
	GameState.time_of_day = 0.875
	game.world_audio._process(1)
	check(game.world_audio.night.volume_db>-30,"Night ambience fades in at night")
	GameState.time_of_day = 0.375
	game.world_audio._process(1)
	check(game.world_audio.night.volume_db<-60 and game.world_audio.wind.volume_db>-35,"Daylight fades out insects and preserves wind")
	game.stage = game.Stage.COMPLETE
	GameState.ending_started = true
	GameState.night_boss_defeated = {"buto":true,"banaspati":true,"headless":true,"commander":true}
	for id in ["pulang","bertahan","jejak"]:
		game._show_ending(id)
		await frames(2)
		var director: Node = game.ending_director
		check(director.art.texture!=null and director.sections.size()>=3,"Illustrated epilogue loads distinct art and narrative sections: "+id)
		check(director.score.stream.get_length()>30 and director.score.stream.loop,"Epilogue music is decoded and looped")
		director.advance()
		director.advance()
		check(director.index==1,"Reading and advancing the epilogue works")
		director.finish()
		await frames(2)
		check(not is_instance_valid(game.ending_director) and game.overlay_mode=="ending" and game.overlay.visible,"Skipping/completing leaves the full ending card accessible")
	check(GameState.unlocked_endings.size()==3,"All three illustrated endings can be recorded")
	game.queue_free()
	await frames(4)
	print("POLISH_PRESENTATION failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

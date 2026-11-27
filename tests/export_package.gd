extends SceneTree
## Run with --main-pack <export.pck> --script <absolute path to this file>.
var failures := 0
func _initialize() -> void: _run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.reset_campaign()
	check(state.upgrade_points==600 and state.player_max_stamina()==200 and state.player_max_health()==3,"Current progression ships in the pack")
	check(is_equal_approx(state.day_phase_duration(1),150) and is_equal_approx(state.day_phase_duration(3),150),"Noon and night each last 150 seconds in the package")
	check(root.has_node("AudioPrefs") and ResourceLoader.exists("res://scripts/campaign_save.gd"),"Save and audio services ship in the pack")
	for data in ["progression","boss_assets","boss_tuning","buto_sfx","headless_sfx","world_audio","audio_mix","sword_slashes","diponegoro_arrest","night_encounters","chapter_four","chapter_five","endings"]:
		check(JSON.parse_string(FileAccess.get_file_as_string("res://data/"+data+".json")) is Dictionary,"Packaged JSON: "+data)
	var history_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/diponegoro_arrest.json"))
	check(history_data.slides.size()==8 and ResourceLoader.exists("res://scripts/history_slideshow.gd"),"Historical slideshow ships in the web package")
	for slide: Dictionary in history_data.slides:
		check(load(str(slide.image)) is Texture2D,"Distinct historical illustration ships: "+str(slide.heading))
	var ulti_f := InputEventKey.new()
	ulti_f.physical_keycode = KEY_F
	var old_ulti_l := InputEventKey.new()
	old_ulti_l.physical_keycode = KEY_L
	check(InputMap.event_is_action(ulti_f,"ultimate") and not InputMap.event_is_action(old_ulti_l,"ultimate"),"The packaged ultimate is bound to F, not the old L key")
	for name in ["01-Tegalrejo","02-Jalur-Hutan","03-Selarong","04-Pemukiman-Terdampak","05-Magelang"]:
		check(load("res://assets/Asset in game/peta/"+name+".png") is Texture2D,"Map preview ships: "+name)
	check(load("res://assets/Generated/Menu/title-keyart-v1.png") is Texture2D,"Generated title artwork ships")
	check(load("res://assets/Fonts/CormorantGaramond.ttf") is Font and FileAccess.file_exists("res://assets/Fonts/OFL-CormorantGaramond.txt"),"Title font and its license ship together")
	for id in ["pulang","bertahan","jejak"]:
		check(load("res://assets/Generated/Endings/"+id+"-v1.png") is Texture2D,"Distinct ending illustration ships: "+id)
	for chapter in ["bab_desa_terdampak","bab_magelang"]:
		var game: Node = load("res://"+chapter+".tscn").instantiate()
		root.add_child(game)
		await frames(5)
		while state.dialogue_active: game.advance_dialogue()
		check(game.panorama.get_child_count()>3 and is_instance_valid(game.day_night.sky),"Late chapter art and sky load: "+chapter)
		check(is_instance_valid(game.upgrade_hut.hut) and is_instance_valid(game.journey),"Upgrade hut and map controller load")
		check(game.player.anim.sprite_frames.get_frame_texture("ultimate",0).resource_path.contains("ultimate_clean"),"Clean ultimate ships")
		for index in range(1,4):
			check(game.player.combat_audio.streams["swing_%d" % index].resource_path.ends_with("/slash-%02d.wav" % index),"Prepared sword audio ships in combo order")
		check(game.world_audio.night.stream.get_length()>20 and game.world_audio.wind.stream.loop,"World ambience ships")
		check(game.world_audio.day_music.stream.get_length()>190 and game.world_audio.day_music.bus=="Music","The supplied daytime theme ships in the package")
		check(game.world_audio.night_music.stream.get_length()>190 and game.world_audio.night_music.bus=="Music","The supplied night theme ships in the package")
		game.queue_free()
		await frames(4)
	for kind in ["buto","banaspati","headless","commander"]:
		state.boss_trial_kind = kind
		var arena: Node = load("res://boss_trial.tscn").instantiate()
		root.add_child(arena)
		await frames(70)
		check(arena.boss.health>0 and arena.player.controls_enabled,"Packaged boss spawns: "+kind)
		for animation in arena.boss.sprite.sprite_frames.get_animation_names():
			check(arena.boss.sprite.sprite_frames.get_frame_count(animation)>0,"Mapped animation ships: "+kind+"/"+animation)
		if kind in ["buto","headless"]: check(arena.sounds.size()==12,"Complete 12-event SFX pack: "+kind)
		if kind=="headless":
			check(int(arena.boss.tuning.phase_count)==2,"Headless has two HP bars in the package")
			check(is_equal_approx(arena.boss.sprite.scale.y,0.62),"Smaller Headless scale ships")
			check(arena.boss_music.stream.resource_path.ends_with("headless-horseman.ogg") and arena.boss_music.stream.get_length()>185,"The supplied Headless score ships")
		if kind=="commander": check(arena.sounds.has("shot") and arena.boss_music.stream.resource_path.ends_with("commander-final-theme.ogg") and arena.boss_music.stream.get_length()>165,"The supplied final boss score and shot ship")
		if kind=="banaspati": check(arena.sounds.size()==9,"All Banaspati SFX ship")
		arena.queue_free()
		await frames(4)
	check(not FileAccess.file_exists("res://docs/COMMANDER_ASSET_PROMPTS.json") and not FileAccess.file_exists("res://assets/Generated/Bosses/Sources/Commander/idle-v1.png"),"Pack excludes documentation and raw sheets")
	print("EXPORT_PACKAGE failures=",failures)
	quit(0 if failures==0 else 1)

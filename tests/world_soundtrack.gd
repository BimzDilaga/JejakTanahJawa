extends Node
var failures := 0
var game: Node
func _ready() -> void: _run.call_deferred()
func frames(count: int) -> void:
	for index in range(count): await get_tree().physics_frame
func wall_seconds(duration: float) -> void:
	var end := Time.get_ticks_msec()+roundi(duration*1000)
	while Time.get_ticks_msec()<end: await get_tree().process_frame
func peak_level(recording: AudioStreamWAV) -> float:
	if recording==null or recording.data.is_empty(): return 0.0
	check(recording.format==AudioStreamWAV.FORMAT_16_BITS,"Mixer recording uses PCM16")
	var peak := 0
	for index in range(0,recording.data.size()-1,2):
		peak = maxi(peak,absi(recording.data.decode_s16(index)))
	return float(peak)/32768.0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures+=1
		push_error(message)
func _run() -> void:
	preload("res://tests/test_session.gd").isolate("world_soundtrack")
	game = load("res://bab_tegalrejo.tscn").instantiate()
	add_child(game)
	await frames(6)
	var audio: Node = game.world_audio
	check(is_instance_valid(audio.day_music) and audio.day_music.stream.get_length()>190,"The supplied daytime theme decodes at its full length")
	check(audio.day_music.bus=="Music" and audio.day_music.stream.loop,"Daytime soundtrack loops through the music slider")
	check(audio.wind.bus=="Ambience" and audio.night.bus=="Ambience","Environment audio remains on its own volume bus")
	game.start_chapter()
	while GameState.dialogue_active: game.advance_dialogue()
	GameState.time_of_day = 0.375
	audio._process(3)
	check(audio.day_music.volume_db>-30,"The daytime theme is audible during exploration")
	if DisplayServer.get_name()!="headless":
		AudioPrefs.set_level("Ambience",0)
		await wall_seconds(1.7)
		audio.day_music.seek(12)
		check(audio.day_music.playing,"The daytime soundtrack is actually playing in the native runtime")
		var recorder := AudioEffectRecord.new()
		AudioServer.add_bus_effect(0,recorder)
		var effect_index := AudioServer.get_bus_effect_count(0)-1
		recorder.set_recording_active(true)
		await wall_seconds(1.0)
		recorder.set_recording_active(false)
		var mixed: AudioStreamWAV = recorder.get_recording()
		check(peak_level(mixed)>0.0001,"The real audio mixer outputs the supplied daytime music")
		if mixed!=null:
			DirAccess.make_dir_recursive_absolute("res://.godot/audio-review")
			mixed.save_to_wav("res://.godot/audio-review/world-day-mix.wav")
		AudioPrefs.set_level("Music",0)
		AudioServer.remove_bus_effect(0,effect_index)
		await wall_seconds(0.5)
		recorder = AudioEffectRecord.new()
		AudioServer.add_bus_effect(0,recorder)
		effect_index = AudioServer.get_bus_effect_count(0)-1
		recorder.set_recording_active(true)
		await wall_seconds(0.5)
		recorder.set_recording_active(false)
		check(peak_level(recorder.get_recording())<0.0001,"The music volume control mutes the actual mixed output below -80 dBFS")
		AudioServer.remove_bus_effect(0,effect_index)
		AudioPrefs.set_level("Music",1)
		AudioPrefs.set_level("Ambience",1)
		remove_child(game)
		await frames(3)
		add_child(game)
		await frames(3)
		check(audio.day_music.playing and audio.wind.playing,"World music and ambience resume after the story scene returns from a boss")
	GameState.time_of_day = 0.75
	audio._process(1)
	check(audio.music_night_mix>0 and audio.music_night_mix<1,"Music crossfades at the beginning of night")
	audio._process(2)
	check(audio.day_music.volume_db<-60 and audio.night.volume_db>-40,"Daytime music fades out while night ambience remains")
	var night_path: String = str(audio.music_settings.get("night_music",""))
	check(is_instance_valid(audio.night_music) if not night_path.is_empty() else not is_instance_valid(audio.night_music),"A night song is used only when an explicit asset is configured")
	GameState.time_of_day = 0.375
	audio._process(3)
	check(audio.day_music.volume_db>-30,"Daytime soundtrack returns after night")
	game.stage = game.Stage.COMPLETE
	audio._process(3)
	check(audio.day_music.volume_db<-60,"World music fades before the completion/ending music")
	audio.stop_all()
	check(not audio.day_music.playing and not audio.wind.playing and not audio.night.playing,"Stopping world audio clears all streams")
	game.queue_free()
	await frames(4)
	GameState.boss_trial_kind = "headless"
	game = load("res://boss_trial.tscn").instantiate()
	add_child(game)
	await frames(70)
	check(not is_instance_valid(game.world_audio.day_music) and not is_instance_valid(game.world_audio.night_music),"World themes do not overlap the boss soundtrack")
	check(game.boss_music.stream.resource_path.ends_with("headless-smoke-and-bronze.ogg"),"The boss retains its own music")
	if DisplayServer.get_name()!="headless":
		game.boss.take_damage(999,0)
		await frames(240)
		game.boss.set_physics_process(false)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/headless-phase-2.png")
	game.queue_free()
	await frames(4)
	print("WORLD_SOUNDTRACK failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

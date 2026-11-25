extends Node
## Run with a native renderer and Dummy audio driver, not --headless.
var failures := 0
func _ready() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func wall_seconds(seconds: float) -> void:
	var end := Time.get_ticks_msec()+roundi(seconds*1000)
	while Time.get_ticks_msec()<end: await get_tree().process_frame
func _run() -> void:
	preload("res://tests/test_session.gd").isolate("boss_audio_playback.gd")
	if DisplayServer.get_name()=="headless":
		push_error("Playback test requires a native renderer")
		get_tree().quit(1)
		return
	GameState.reset_campaign()
	GameState.boss_trial_kind = "buto"
	var arena: Node = load("res://boss_trial.tscn").instantiate()
	add_child(arena)
	for i in range(70): await get_tree().physics_frame
	arena.boss_music.stop()
	arena.world_audio.stop_all()
	arena.boss.set_physics_process(false)
	arena.player.controls_enabled = false
	arena._clear_sound_voices()
	var recorder := AudioEffectRecord.new()
	AudioServer.add_bus_effect(0,recorder)
	recorder.set_recording_active(true)
	check(arena.play_buto_sound("light_swing",arena.player.position),"A live event starts a spatial audio player")
	check(arena.sound_voices.get_child_count()==1 and arena.sound_voices.get_child(0).playing,"Actual AudioStreamPlayer2D is playing the generated sound")
	await wall_seconds(1.0)
	recorder.set_recording_active(false)
	var recording: AudioStreamWAV = recorder.get_recording()
	check(recording!=null and not recording.data.is_empty(),"Audio mixer produces a recording")
	if recording!=null:
		var nonzero := false
		for value in recording.data:
			if value!=0:
				nonzero = true
				break
		check(nonzero,"Live mixed output contains the SFX, not silence")
		DirAccess.make_dir_recursive_absolute("res://.godot/audio-review")
		recording.save_to_wav("res://.godot/audio-review/buto-live-mix.wav")
	check(arena.sound_voices.get_child_count()==0,"Finished voices clean themselves up")
	var old_voices: Array[Node] = []
	for i in range(20): arena._play_sound("spawn",arena.boss.position,-18)
	check(arena.sound_voices.get_child_count()==12,"Concurrent players cap at twelve, including automatically renamed nodes")
	old_voices = arena.sound_voices.get_children()
	arena._retry_trial()
	check(arena.sound_voices.get_child_count()==1,"Retry can immediately play its new spawn sound")
	for voice in old_voices:
		check(not voice.playing and voice.get_parent()==null and voice.is_queued_for_deletion(),"Retry stops and removes every old voice")
	arena.queue_free()
	await get_tree().process_frame
	print("BOSS_AUDIO_PLAYBACK failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

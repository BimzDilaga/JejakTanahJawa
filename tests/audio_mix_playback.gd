extends Node
## Native audio QA: record the actual mixer after limiting, never the user's settings.
var failures := 0
const Combat = preload("res://scripts/combat_audio.gd")
const Hazard = preload("res://scripts/boss_hazard.gd")
func _ready() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func wall_seconds(duration: float) -> void:
	var end := Time.get_ticks_msec()+roundi(duration*1000)
	while Time.get_ticks_msec()<end: await get_tree().process_frame
func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame
func capture(label: String, trigger: Callable) -> void:
	var recorder := AudioEffectRecord.new()
	AudioServer.add_bus_effect(0,recorder)
	var index := AudioServer.get_bus_effect_count(0)-1
	recorder.set_recording_active(true)
	trigger.call()
	await wall_seconds(0.85)
	recorder.set_recording_active(false)
	var recording: AudioStreamWAV = recorder.get_recording()
	var peak := 0.0
	var total := 0.0
	var samples := 0
	if recording!=null:
		for offset in range(0,recording.data.size()-1,2):
			var value: float = float(recording.data.decode_s16(offset))/32768.0
			peak = maxf(peak,absf(value))
			total += value*value
			samples += 1
		DirAccess.make_dir_recursive_absolute("res://.godot/audio-review")
		recording.save_to_wav("res://.godot/audio-review/mix-"+label+".wav")
	var rms: float = sqrt(total/maxi(1,samples))
	check(peak>0.01 and rms>0.002,"Audible live audio: "+label)
	check(peak<=0.901,"Master output remains below the -1 dB ceiling: "+label)
	print("MIX_REVIEW ",label," rms_db=",linear_to_db(maxf(rms,0.000001))," peak_db=",linear_to_db(maxf(peak,0.000001)))
	AudioServer.remove_bus_effect(0,index)
func check_parry_voice(combat: Node, context: String) -> void:
	var voice: AudioStreamPlayer
	for candidate: Node in combat.get_children():
		if candidate is AudioStreamPlayer and candidate.stream==load("res://assets/Generated/Audio/Combat/parry.wav") and candidate.playing and not candidate.is_queued_for_deletion():
			voice = candidate
			break
	# A simultaneous boss stance break may add another cue after the parry.
	check(voice!=null,"Canonical playing parry in "+context)
	if voice==null: return
	check(is_equal_approx(voice.volume_db,-5.0),"Parry volume is consistent in "+context)
func _run() -> void:
	preload("res://tests/test_session.gd").isolate("audio_mix_playback")
	if DisplayServer.get_name()=="headless":
		push_error("Run audio_mix_playback with a native renderer and Dummy audio driver")
		get_tree().quit(1)
		return
	AudioPrefs.set_level("Ambience",0)
	var regular := Combat.new()
	add_child(regular)
	for index in range(1,4):
		await capture("jaka-slash-%d" % index,func() -> void:
			regular.play_effect("swing_%d" % index)
			check(regular.get_child(regular.get_child_count()-1).stream.resource_path.ends_with("/slash-%02d.wav" % index),"Live slash follows combo source order"))
		regular.stop_all()
		await frames(2)
	var other: AudioStream = load("res://assets/Generated/Audio/Headless/parry.wav")
	regular.play_effect("parry",other)
	check_parry_voice(regular,"regular exploration even with a legacy override")
	regular.stop_all()
	await frames(2)
	for kind: String in ["buto","banaspati","headless","commander"]:
		GameState.boss_trial_kind = kind
		var arena: Node = load("res://boss_trial.tscn").instantiate()
		add_child(arena)
		await frames(70)
		arena.boss.set_physics_process(false)
		arena._clear_hazards()
		arena._clear_sound_voices()
		AudioPrefs.set_level("SFX",0)
		AudioPrefs.set_level("Music",1)
		await capture(kind+"-music",func() -> void: arena.boss_music.seek(35))
		AudioPrefs.set_level("Music",0)
		AudioPrefs.set_level("SFX",1)
		arena.player.position = Vector2(600,570)
		arena.player.reset_health()
		arena.boss.position = Vector2(710,570)
		arena.boss.facing = -1
		arena.boss.attack = {"animation":"light","effect":"melee","heavy":false}
		await capture(kind+"-parry",func() -> void:
			arena.player.perform_parry()
			arena.boss._strike()
			check_parry_voice(arena.player.combat_audio,kind+" melee"))
		arena.player.combat_audio.stop_all()
		arena.player.reset_health()
		await frames(2)
		var shot := Hazard.new()
		shot.target = arena.player
		shot.owner_boss = arena.boss
		shot.visual_kind = "commander"
		arena.world.add_child(shot)
		arena.player.perform_parry()
		shot._damage_target()
		check_parry_voice(arena.player.combat_audio,kind+" projectile")
		arena.player.combat_audio.stop_all()
		arena.player.reset_health()
		await frames(2)
		arena.player.stance = arena.player.STANCE_MAX
		arena.player.ultimate_charge = arena.player.ULTIMATE_HITS
		check(arena.player.perform_ultimate(),"Ulti starts at a full stance bar")
		arena.boss.attack.heavy = true
		arena.boss._strike()
		check(arena.player.health==arena.player.max_health and arena.player.ultimate_time>0 and arena.player.stance==arena.player.STANCE_MAX and arena.player.stun_time==0,"Ulti auto parry blocks boss heavy damage without stance cost or stun: "+kind)
		check_parry_voice(arena.player.combat_audio,kind+" ulti auto parry")
		arena.queue_free()
		await frames(4)
	await wall_seconds(0.2)
	await capture("overlapping-limiter",func() -> void:
		for i in range(4):
			var loud := AudioStreamPlayer.new()
			loud.stream = load("res://assets/Generated/Audio/Combat/parry.wav")
			loud.bus = "SFX"
			loud.volume_db = 0
			add_child(loud)
			loud.finished.connect(loud.queue_free)
			loud.play())
	regular.queue_free()
	print("AUDIO_MIX_PLAYBACK failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

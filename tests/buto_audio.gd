extends Node
var failures := 0
class ParryProbe extends "res://scripts/combat_audio.gd":
	var selected: AudioStream
	func play_effect(_key: String, override: AudioStream = null) -> void:
		selected = override
func _ready() -> void: _run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	preload("res://tests/test_session.gd").isolate("buto_audio.gd")
	GameState.reset_campaign()
	GameState.boss_trial_kind = "buto"
	var arena: Node = load("res://boss_trial.tscn").instantiate()
	add_child(arena)
	await frames(70)
	var pack: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/buto_sfx.json"))
	check(pack.status=="ready_procedural" and arena.sounds.size()==12,"All twelve generated Buto clips are loaded")
	var hashes := {}
	for key in pack.clips:
		var clip: AudioStreamWAV = arena.sounds[key]
		check(clip.mix_rate==44100 and not clip.stereo and not clip.data.is_empty() and clip.loop_mode==AudioStreamWAV.LOOP_DISABLED,"Decoded mono one-shot format: "+str(key))
		check(clip.get_length()>0.3 and clip.get_length()<3,"Compact decoded clip: "+str(key))
		check(is_equal_approx(float(clip.get_meta("combat_volume_db")),float(pack.clips[key].volume_db)),"Per-event mix level including custom parry: "+str(key))
		var fingerprint: int = hash(clip.data)
		check(not hashes.has(fingerprint),"Distinct sound data: "+str(key))
		hashes[fingerprint] = true
	check(arena._last_sound.has("spawn"),"Entrance triggers the spawn roar")
	arena.player.position = Vector2(270,570)
	arena.boss.position = Vector2(1400,570)
	arena.boss._set_state("idle")
	await frames(40)
	check(arena._last_sound.has("footstep_a") and arena._last_sound.has("footstep_b"),"Walking alternates the two footstep sounds")
	arena.boss.set_physics_process(false)
	arena.player.position = Vector2(600,570)
	arena.boss.position = Vector2(740,570)
	arena.boss.facing = -1
	arena.boss.attack = {"animation":"light","effect":"melee","heavy":false}
	arena.boss.combo_index = 0
	arena.boss._strike()
	arena.player.reset_health()
	arena.boss.combo_index = 1
	arena.boss._strike()
	check(arena._last_sound.has("light_swing") and arena._last_sound.has("reverse_swing"),"Light and reverse strikes trigger different swings")
	arena.boss.combo.assign([{"animation":"heavy","effect":"melee","heavy":true}])
	arena.boss.combo_index = 0
	arena.boss._begin_strike()
	arena.player.reset_health()
	arena.boss._strike()
	check(arena._last_sound.has("heavy_windup") and arena._last_sound.has("heavy_impact"),"Heavy telegraph and impact trigger separate sounds")
	arena.player.reset_health()
	var probe := ParryProbe.new()
	arena.player.combat_audio.queue_free()
	arena.player.add_child(probe)
	arena.player.combat_audio = probe
	arena.player.perform_parry()
	arena.boss.attack = {"animation":"light","effect":"melee","heavy":false}
	arena.boss._strike()
	check(probe.selected==arena.sounds.parry and arena.player.health==3,"Successful live parry selects the Buto metal clash and prevents damage")
	arena.emit_boss_attack(arena.boss,"earth_wave")
	check(arena._last_sound.has("wave"),"Earth shockwave triggers its ground fracture sound")
	arena._clear_hazards()
	arena.boss.take_damage(1,0)
	check(arena._last_sound.has("pain"),"Boss damage triggers a pain grunt")
	arena.boss._break_stance()
	check(arena._last_sound.has("break"),"Stance break triggers the knee/metal cue")
	var next_allowed := Time.get_ticks_msec()/1000.0
	arena._last_sound.pain = next_allowed
	arena.play_buto_sound("pain",arena.boss.position)
	check(arena._last_sound.pain==next_allowed,"Repeated hurt cannot spam the same sound inside its cooldown")
	arena.boss.take_damage(999,0)
	check(arena._last_sound.has("death") and not arena.boss.dead,"First phase knockdown triggers the fall sound without recording a win")
	arena._last_sound.erase("spawn")
	arena.boss.set_physics_process(true)
	await frames(240)
	check(arena.boss.phase==2 and arena._last_sound.has("spawn"),"Rising into phase two triggers a new roar")
	arena._retry_trial()
	await frames(2)
	check(arena.sounds.size()==12 and not arena._last_sound.has("death") and not arena._last_sound.has("pain"),"Retry preserves loaded audio and clears prior event cooldowns")
	arena.queue_free()
	await frames(4)
	print("BUTO_AUDIO failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

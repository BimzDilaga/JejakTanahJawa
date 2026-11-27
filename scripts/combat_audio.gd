extends Node
## Bounded non-positional cues; no voice survives a retry or scene change.
var streams: Dictionary = {}
func _ready() -> void:
	for key in ["parry","boss-stance-break"]:
		streams[key] = load("res://assets/Generated/Audio/Combat/"+key+".wav")
	for index in range(1,4):
		var file := "res://assets/Generated/Audio/Combat/SwordSlashes/slash-%02d.wav" % index
		if not ResourceLoader.exists(file):
			file = "res://assets/Generated/Audio/Temporary/keris-swing-%d.wav" % index
		if ResourceLoader.exists(file): streams["swing_%d" % index] = load(file)

func play_effect(key: String, override: AudioStream = null) -> void:
	if DisplayServer.get_name()=="headless" or not streams.has(key) or get_child_count()>=4: return
	var voice := AudioStreamPlayer.new()
	voice.bus = "SFX"
	# One canonical parry cue in story, projectiles, and every boss arena.
	var selected: AudioStream = streams[key] if key=="parry" or override==null else override
	voice.stream = selected
	var default_volume: float = AudioPrefs.mix_db("stance_break_db",-6.0)
	if key.begins_with("swing_"): default_volume = AudioPrefs.mix_db("keris_swing_db",-8.0)
	elif key=="parry": default_volume = AudioPrefs.mix_db("parry_db",-5.0)
	voice.volume_db = float(selected.get_meta("combat_volume_db",default_volume)) if key!="parry" else default_volume
	add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()

func stop_all() -> void:
	for voice in get_children():
		voice.stop()
		voice.queue_free()

extends Node
## Bounded non-positional cues; no voice survives a retry or scene change.
var streams: Dictionary = {}
func _ready() -> void:
	for key in ["parry","boss-stance-break"]:
		streams[key] = load("res://assets/Generated/Audio/Combat/"+key+".wav")
	for index in range(1,4):
		var file := "res://assets/Generated/Audio/Temporary/keris-swing-%d.wav" % index
		if ResourceLoader.exists(file): streams["swing_%d" % index] = load(file)

func play_effect(key: String, override: AudioStream = null) -> void:
	if DisplayServer.get_name()=="headless" or not streams.has(key) or get_child_count()>=4: return
	var voice := AudioStreamPlayer.new()
	voice.bus = "SFX"
	voice.stream = override if override!=null else streams[key]
	var default_volume := -20.0 if key.begins_with("swing_") else -14.0
	voice.volume_db = float(override.get_meta("combat_volume_db",default_volume)) if override!=null else default_volume
	add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()

func stop_all() -> void:
	for voice in get_children():
		voice.stop()
		voice.queue_free()

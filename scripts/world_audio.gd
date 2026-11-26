extends Node
## Separate world music and ambience; boss arenas retain their dedicated score.
var chapter: Node
var wind: AudioStreamPlayer
var night: AudioStreamPlayer
var intensity := 0.0
var day_music: AudioStreamPlayer
var night_music: AudioStreamPlayer
var music_settings: Dictionary
var music_night_mix := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	wind = _voice("res://assets/Generated/Audio/Ambience/day-wind.ogg")
	night = _voice("res://assets/Generated/Audio/Ambience/night-village.ogg")
	music_settings = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_audio.json"))
	music_night_mix = 1.0 if chapter.day_night.phase_index(GameState.time_of_day)==3 else 0.0
	if not chapter.get_script().resource_path.ends_with("boss_arena.gd"):
		day_music = _voice(str(music_settings.day_music),"Music")
		var night_path: String = str(music_settings.get("night_music",""))
		if not night_path.is_empty(): night_music = _voice(night_path,"Music")

func _voice(path: String, bus := "Ambience") -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	voice.bus = bus
	voice.stream = load(path)
	(voice.stream as AudioStreamOggVorbis).loop = true
	voice.volume_db = -60
	add_child(voice)
	if DisplayServer.get_name()!="headless": voice.play()
	return voice

func _process(delta: float) -> void:
	var playing: bool = chapter.stage not in [chapter.Stage.MENU,chapter.Stage.COMPLETE,chapter.Stage.FAILED]
	intensity = move_toward(intensity,1.0 if playing else 0.0,delta*1.6)
	var amount: float = chapter.day_night.sample_grade(GameState.time_of_day).night
	wind.volume_db = linear_to_db(maxf(0.0001,intensity*(1.0-amount*0.5))) - 29
	night.volume_db = linear_to_db(maxf(0.0001,intensity*amount)) - 26
	var target_mix := 1.0 if chapter.day_night.phase_index(GameState.time_of_day)==3 else 0.0
	music_night_mix = move_toward(music_night_mix,target_mix,delta/maxf(0.1,float(music_settings.crossfade_seconds)))
	if is_instance_valid(day_music):
		day_music.volume_db = linear_to_db(maxf(0.0001,intensity*(1.0-music_night_mix))) + float(music_settings.day_music_db)
	if is_instance_valid(night_music):
		night_music.volume_db = linear_to_db(maxf(0.0001,intensity*music_night_mix)) + float(music_settings.night_music_db)

func stop_all() -> void:
	wind.stop()
	night.stop()
	if is_instance_valid(day_music): day_music.stop()
	if is_instance_valid(night_music): night_music.stop()
	set_process(false)

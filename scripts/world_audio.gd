extends Node
## Two low ambience loops crossfade with the shared day/night grade.
var chapter: Node
var wind: AudioStreamPlayer
var night: AudioStreamPlayer
var intensity := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	wind = _voice("res://assets/Generated/Audio/Ambience/day-wind.ogg")
	night = _voice("res://assets/Generated/Audio/Ambience/night-village.ogg")

func _voice(path: String) -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	voice.bus = "Ambience"
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

func stop_all() -> void:
	wind.stop()
	night.stop()
	set_process(false)

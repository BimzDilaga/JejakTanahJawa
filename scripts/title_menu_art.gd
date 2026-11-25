extends Node
## Displays generated key art; only a slow framing drift and music are procedural.
var menu: Control
var picture: TextureRect
var elapsed := 0.0
var score: AudioStreamPlayer
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	score = AudioStreamPlayer.new()
	score.stream = load("res://assets/Generated/Audio/Music/ending-memory.ogg")
	(score.stream as AudioStreamOggVorbis).loop = true
	score.bus = "Music"
	score.volume_db = -60
	add_child(score)
func _process(delta: float) -> void:
	var active := menu.is_visible_in_tree()
	if active:
		elapsed += delta
		picture.position = Vector2(-8+sin(elapsed*0.055)*6,-6+sin(elapsed*0.04)*4)
		if not score.playing and DisplayServer.get_name()!="headless": score.play()
	score.volume_db = move_toward(score.volume_db,-27.0 if active else -60.0,delta*22)
	if not active and score.volume_db<=-59 and score.playing: score.stop()

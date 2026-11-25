extends Node
## Stationary witnesses stay in the village/camp; only nighttime opens the side encounter.
var chapter: Node2D
var entry: Dictionary = {}
var witness: Node2D
var near := false
var accepted := false
var pending := false
var default_prompt_position := Vector2.ZERO
var clue: Node2D
var rumor_learned := false
var near_clue := false

class ClueMark extends Node2D:
	var fiery := false
	var elapsed := 0.0
	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
	func _draw() -> void:
		if fiery:
			for i in range(9):
				var at := Vector2(-55+i*13,-3-absf(sin(elapsed*1.7+i))*10)
				draw_circle(at,9,Color(1,0.25,0.01,0.08))
				draw_rect(Rect2(at,Vector2(3,3)),Color("ef9d38"))
		else:
			for i in range(3):
				draw_line(Vector2(-60,-2+i*3),Vector2(60,-5+i*3),Color("ad9873"),2)
			draw_circle(Vector2(0,-16),3,Color("e9d4a1"))

class WitnessLantern extends Node2D:
	var elapsed := 0.0
	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
	func _draw() -> void:
		var light := Vector2(0,-44)
		draw_circle(light,25,Color(1.0,0.30,0.025,0.14+sin(elapsed*3)*0.02))
		draw_circle(light,12,Color(1.0,0.36,0.04,0.25))
		draw_line(Vector2.ZERO,Vector2(0,-54),Color("6a4c30"),3)
		draw_rect(Rect2(-6,-49,12,14),Color("433024"))
		draw_rect(Rect2(-3,-47,6,10),Color("ff6512"))

func _ready() -> void:
	default_prompt_position = chapter.prompt.position
	var entries: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/night_encounters.json"))
	entry = entries.get(chapter.get_script().resource_path.get_file(),{})
	if entry.is_empty(): return
	var region: Array = entry.region
	witness = chapter._npc(entry.speaker,entry.portrait,Rect2(region[0],region[1],region[2],region[3]),float(entry.x))
	witness.name = "NightWitness_"+str(entry.kind)
	witness.add_to_group("night_witnesses")
	var lantern := WitnessLantern.new()
	lantern.position.x = 36
	witness.add_child(lantern)
	witness.hide()
	clue = ClueMark.new()
	clue.name = "NightClue_"+str(entry.kind)
	clue.fiery = entry.kind=="banaspati"
	clue.position = Vector2(float(entry.clue_x),chapter.FLOOR_Y)
	chapter.world.add_child(clue)
	clue.hide()

func is_night() -> bool:
	return GameState.time_of_day>=0.75 and GameState.time_of_day<1.0

func can_interact() -> bool:
	return is_instance_valid(witness) and witness.visible and not chapter.paused and not chapter.overlay.visible and not GameState.dialogue_active and not GameState.ending_started and chapter.player.controls_enabled

func _process(_delta: float) -> void:
	if not is_instance_valid(witness): return
	witness.visible = is_night() and chapter.stage not in [chapter.Stage.MENU,chapter.Stage.INTRO,chapter.Stage.COMPLETE,chapter.Stage.FAILED,chapter.Stage.TRANSITION]
	near = can_interact() and chapter.player.position.distance_to(witness.position)<125
	clue.visible = witness.visible and rumor_learned and not GameState.night_boss_defeated.get(entry.kind,false)
	near_clue = can_interact() and clue.visible and chapter.player.position.distance_to(clue.position)<125
	chapter.prompt.position = Vector2(390,574) if near or near_clue else default_prompt_position
	if near: chapter.prompt.text = "[ E ]  Dengar rumor malam"
	elif near_clue: chapter.prompt.text = "[ E ]  "+str(entry.clue_name)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and (near or near_clue) and can_interact():
		if near_clue: investigate()
		else: talk()
		get_viewport().set_input_as_handled()

func talk() -> void:
	if not can_interact() or chapter.player.position.distance_to(witness.position)>=125: return
	accepted = false
	pending = true
	if GameState.night_boss_defeated.get(entry.kind,false):
		chapter._start_dialogue([{"speaker":entry.speaker,"text":entry.after}],func() -> void: pending=false)
		return
	var content: Array = [
		{"speaker":entry.speaker,"text":entry.rumor},
		{"speaker":entry.speaker,"text":entry.invitation,"choices":[
			{"text":"Ikuti petunjuknya.","reply":entry.accepted,"enter_night_boss":true},
			{"text":"Belum sekarang.","reply":"Tidak apa-apa. Kembalilah saat kau sudah siap.","enter_night_boss":false}
		]}
	]
	chapter._start_dialogue(content,func() -> void:
		pending = false
		if accepted: rumor_learned = true)

func investigate() -> void:
	if not can_interact() or not rumor_learned or not clue.visible or chapter.player.position.distance_to(clue.position)>=125: return
	accepted = false
	pending = true
	chapter._start_dialogue([
		{"speaker":"Jaka","text":entry.clue_text},
		{"speaker":"Jaka","text":"Aku sudah menemukan petunjuknya. Apakah aku siap melanjutkan?","choices":[
			{"text":"Dekati sumbernya.","reply":"Aku harus membaca gerakannya dan mencari celah.","enter_night_boss":true},
			{"text":"Kembali dulu.","reply":"Aku bisa kembali ke sini pada malam hari setelah bersiap.","enter_night_boss":false}
		]}
	],func() -> void:
		pending = false
		if accepted: travel.call_deferred())

func note_choice(choice: Dictionary) -> void:
	if pending and choice.has("enter_night_boss"): accepted = bool(choice.enter_night_boss)

func travel() -> void:
	if not is_night() or GameState.ending_started or not rumor_learned or chapter.player.position.distance_to(clue.position)>=125: return
	var tree := get_tree()
	chapter.player.combat_audio.stop_all()
	GameState.hold_encounter_origin(chapter)
	GameState.boss_trial_kind = str(entry.kind)
	tree.current_scene = null
	chapter.get_parent().remove_child(chapter)
	var arena: Node = load("res://boss_trial.tscn").instantiate()
	tree.root.add_child(arena)
	tree.current_scene = arena

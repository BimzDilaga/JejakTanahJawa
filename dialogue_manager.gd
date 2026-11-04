extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var name_label: Label = $Panel/NameLabel
@onready var text_label: Label = $Panel/TextLabel

var current_lines: Array[String] = []
var line_index: int = 0
var pending_objective: String = ""
var pending_complete: bool = false

func _ready() -> void:
	panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if GameState.dialogue_active and event.is_action_just_pressed("interact"):
		next_line()

func start_dialogue(speaker: String, lines: Array[String], next_obj: String = "", complete_now: bool = false) -> void:
	if lines.is_empty():
		return
	GameState.dialogue_active = true
	GameState.dialogue_started.emit()
	current_lines = lines
	line_index = 0
	pending_objective = next_obj
	pending_complete = complete_now
	name_label.text = speaker
	show_current_line()
	panel.visible = true

func show_current_line() -> void:
	text_label.text = current_lines[line_index]

func next_line() -> void:
	line_index += 1
	if line_index < current_lines.size():
		show_current_line()
	else:
		end_dialogue()

func end_dialogue() -> void:
	panel.visible = false
	GameState.dialogue_active = false
	GameState.dialogue_ended.emit()
	if pending_objective != "":
		GameState.set_objective(pending_objective, pending_complete)

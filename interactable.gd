extends Area2D

@export var speaker_name: String = "Warga"
@export_multiline var dialogue_lines: Array[String] = []
@export var is_supply_point: bool = false
@export var next_objective_text: String = ""
@export var marks_objective_complete: bool = false

var already_checked: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.current_interactable = self

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" and body.current_interactable == self:
		body.current_interactable = null

func trigger_interaction() -> void:
	if is_supply_point:
		if not already_checked:
			already_checked = true
			GameState.add_supply_check()
			monitoring = false
		return

	# Jalankan dialog jika ada isi teksnya
	if dialogue_lines.size() > 0:
		DialogueManager.start_dialogue(speaker_name, dialogue_lines, next_objective_text, marks_objective_complete)

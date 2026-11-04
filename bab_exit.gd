extends Area2D

@export_file("*.tscn") var target_scene_path: String

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		if GameState.objective_completed:
			GameState.reset_stage()
			get_tree().change_scene_to_file(target_scene_path)
		else:
			GameState.objective_updated.emit("Selesaikan tujuan terlebih dahulu.")
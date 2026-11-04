extends Area2D
signal exit_requested
var triggered: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_entered)

func _entered(body: Node2D) -> void:
	if body.is_in_group("player") and GameState.objective_completed and not triggered:
		triggered = true
		exit_requested.emit()

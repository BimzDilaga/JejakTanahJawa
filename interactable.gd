extends Area2D
## Reusable proximity interaction. The chapter owns narrative progression.
signal interaction_requested
var player_near: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			player_near = true)
	body_exited.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			player_near = false)

func trigger_interaction() -> void:
	if player_near and not GameState.dialogue_active:
		interaction_requested.emit()

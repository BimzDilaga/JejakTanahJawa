extends Node2D

const SPEED := 720.0
var direction := 1
var distance_left := 475.0

func _ready() -> void:
	add_to_group("patrol_shots")

func _physics_process(delta: float) -> void:
	if GameState.ending_started or distance_left <= 0.0:
		queue_free()
		return
	if GameState.dialogue_active:
		return
	var travel := minf(distance_left, SPEED * delta)
	var next := global_position + Vector2(travel * direction, 0.0)
	var query := PhysicsRayQueryParameters2D.create(global_position, next, 3)
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var body: Node = hit.collider
		if body.is_in_group("player"):
			body.take_damage(1, global_position.x, true)
		queue_free()
		return
	global_position = next
	distance_left -= travel

func _draw() -> void:
	draw_line(Vector2(-14.0 * direction, 0.0), Vector2.ZERO, Color("ffd985"), 3.0, true)

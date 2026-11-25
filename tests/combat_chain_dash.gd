extends Node2D
var failures := 0
var player: CharacterBody2D
class Target extends Node2D:
	var active := true
	var dead := false
	var hits := 0
	func take_damage(amount: int, _source: float) -> bool:
		hits += amount
		return true
func _ready() -> void: _run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func mouse(button: MouseButton, pressed: bool, at := Vector2(500,350)) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	get_viewport().push_input(motion,true)
	await frames(1)
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = at
	event.global_position = at
	get_viewport().push_input(event,true)
	await frames(2)
func shift(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SHIFT
	event.keycode = KEY_SHIFT
	event.shift_pressed = pressed
	event.pressed = pressed
	Input.parse_input_event(event)
	await frames(2)
func jump(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.keycode = KEY_SPACE
	event.pressed = pressed
	Input.parse_input_event(event)
	await frames(2)
func _run() -> void:
	preload("res://tests/test_session.gd").isolate("combat_chain_dash.gd")
	GameState.upgrade_levels.heart = 2
	GameState.reset_stage()
	var floor_body := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(4000,100)
	collider.shape = shape
	floor_body.position = Vector2(1500,620)
	floor_body.add_child(collider)
	add_child(floor_body)
	player = preload("res://player.tscn").instantiate()
	player.position = Vector2(400,570)
	add_child(player)
	var target := Target.new()
	target.position = Vector2(480,570)
	target.add_to_group("enemies")
	add_child(target)
	await frames(5)
	check(InputMap.action_get_events("attack")[0] is InputEventMouseButton and InputMap.action_get_events("attack")[0].button_index==MOUSE_BUTTON_LEFT,"Attack binding is left mouse")
	check(InputMap.action_get_events("parry")[0] is InputEventMouseButton and InputMap.action_get_events("parry")[0].button_index==MOUSE_BUTTON_RIGHT,"Parry binding is right mouse")
	await mouse(MOUSE_BUTTON_LEFT,true)
	check(player.is_attacking,"A real left click starts combat")
	await frames(30)
	check(not player.is_attacking and target.hits==1,"Holding left click does not auto-repeat")
	await mouse(MOUSE_BUTTON_LEFT,false)
	player.reset_health()
	await mouse(MOUSE_BUTTON_RIGHT,true)
	check(player.parry_time>0 and player.anim.frame==0,"A real right click opens the parry window")
	await mouse(MOUSE_BUTTON_RIGHT,false)
	player.reset_health()
	var button := Button.new()
	button.position = Vector2(20,20)
	button.size = Vector2(180,70)
	button.text = "UI click"
	add_child(button)
	await frames(3)
	await mouse(MOUSE_BUTTON_LEFT,true,Vector2(50,50))
	await mouse(MOUSE_BUTTON_LEFT,false,Vector2(50,50))
	check(not player.is_attacking,"UI button clicks never leak into combat")
	button.queue_free()
	await frames(3)
	Input.action_press("move_right")
	await shift(true)
	check(player.dash_time>0 and Input.is_action_pressed("sprint"),"Pressing Shift starts dash and holding also enables sprint")
	await frames(72)
	check(player.dash_time==0 and is_equal_approx(player.velocity.x,260),"Holding Shift runs without automatically repeating dash")
	await shift(false)
	await frames(3)
	check(is_equal_approx(player.velocity.x,160),"Releasing Shift returns to walking")
	Input.action_release("move_right")
	player.reset_health()
	player.position.x = 400
	target.hits = 0
	player.perform_attack()
	player.perform_attack()
	await frames(24)
	check(target.hits==1 and not player.is_attacking,"One press and premature buffering produce one hit only")
	await frames(15)
	player.reset_health()
	target.hits = 0
	player.perform_attack()
	await frames(10)
	player.perform_attack()
	await frames(13)
	check(player.combo_step==2,"A fresh press during recovery starts the second strike")
	await frames(8)
	player.perform_attack()
	await frames(16)
	check(player.combo_step==3,"A second buffered press starts the finisher")
	await frames(10)
	player.perform_attack()
	await frames(35)
	check(target.hits==3 and not player.is_attacking and player.ultimate_charge==3,"Three strikes each hit once and cannot chain into a fourth")
	player.reset_health()
	player.perform_attack()
	await frames(9)
	player.perform_attack()
	check(player.perform_parry() and player.combo_step==0,"Parry clears a buffered combo")
	await frames(30)
	check(not player.is_attacking,"A cancelled follow-up never resumes later")
	player.reset_health()
	player.position.x = 400
	player.facing = 1
	var start := player.position.x
	check(player.perform_dash(),"Forward dash starts")
	check(not player.perform_dash(true),"Forward and backward dash share cooldown")
	await frames(12)
	check(player.position.x-start>100 and player.position.x-start<130,"Short dash travels about 115 pixels")
	check(player.invulnerable_time==0 and target.hits==3,"Movement dash neither adds invulnerability nor damages targets")
	await frames(51)
	start = player.position.x
	check(player.perform_dash(true),"Backstep returns after one second")
	await frames(12)
	check(start-player.position.x>100 and player.facing==1,"Backstep retreats while watching the same direction")
	for backward in [false,true]:
		player.reset_health()
		player.position = Vector2(400,570)
		player.velocity = Vector2.ZERO
		await frames(3)
		check(player.perform_dash(backward),"Grounded dash starts before jumping")
		await frames(3)
		await jump(true)
		check(player.position.y<570 and player.velocity.y<0 and player.dash_time>0,"Space can jump while a grounded dash is already moving")
		check(is_equal_approx(player.velocity.x,-640 if backward else 640) and player.facing==1,"Jump preserves forward/backward dash momentum and facing")
		check(is_equal_approx(player.stamina,180) and player.dash_cooldown>0.8,"Dash-jump spends normal jump stamina and retains the shared cooldown")
		check(not player.perform_parry(),"Jump permission does not unlock parry during dash")
		await jump(false)
		var rising_speed: float = player.velocity.y
		await jump(true)
		check(player.velocity.y>rising_speed and is_equal_approx(player.stamina,180),"Pressing Space again in the air cannot double jump or spend stamina twice")
		await jump(false)
		await frames(55)
		check(player.is_on_floor(),"Dash-jump keeps gravity and lands normally")
	player.reset_health()
	player.perform_dash()
	player.take_damage(1,player.position.x+20,false)
	check(player.health==4 and player.dash_time==0,"A hit damages and interrupts dash")
	player.reset_health()
	player.position.x = 400
	var wall := StaticBody2D.new()
	var wall_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(30,400)
	wall_shape.shape = rectangle
	wall.add_child(wall_shape)
	wall.position = Vector2(470,450)
	add_child(wall)
	await frames(3)
	player.perform_dash()
	await frames(12)
	check(player.position.x<450,"Dash respects solid walls")
	GameState.dialogue_active = true
	player.reset_health()
	check(not player.perform_dash(),"Dialogue blocks dash")
	GameState.dialogue_active = false
	player.take_damage(99,player.position.x+20)
	await frames(65)
	check(player.anim.animation=="death" and player.anim.frame==5,"Defeat animation reaches and holds its last frame despite locked controls")
	player.reset_health()
	check(player.dash_cooldown==0 and player.combo_step==0,"Retry clears movement and combo state")
	for key in player.combat_audio.streams:
		check(player.combat_audio.streams[key]!=null and player.combat_audio.streams[key].get_length()>0,"Converted combat audio decodes: "+str(key))
	print("COMBAT_CHAIN_DASH failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

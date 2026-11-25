extends Node
var failures := 0
var game: Node
func _ready() -> void: _run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func touch(id: int, pressed: bool, at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.pressed = pressed
	event.position = at
	get_viewport().push_input(event,true)
	await frames(2)
func _run() -> void:
	preload("res://tests/test_session.gd").isolate("device_controls")
	game = load("res://bab_tegalrejo.tscn").instantiate()
	add_child(game)
	await frames(4)
	var controls: Node = game.device_controls
	check(controls.fullscreen_button.visible and not controls.pad.visible,"Desktop menu exposes fullscreen without mobile clutter")
	if DisplayServer.get_name()!="headless":
		controls.toggle_fullscreen()
		await frames(3)
		check(DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN,"Windows fullscreen button changes native window mode")
		var key := InputEventKey.new()
		key.physical_keycode = KEY_F11
		key.pressed = true
		get_viewport().push_input(key,true)
		await frames(3)
		check(DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_WINDOWED,"F11 returns to windowed mode")
	controls.touch_enabled = true
	game.start_chapter()
	await frames(3)
	check(controls.next_button.visible and not controls.pad.visible,"Touch can advance dialogue without covering the dialogue with combat controls")
	while GameState.dialogue_active: game.advance_dialogue()
	await frames(4)
	check(controls.pad.visible and controls.buttons.size()==11 and controls.pause_button.visible,"All eleven touch actions and pause are accessible during gameplay")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/device-controls.png")
	var start: Vector2 = game.player.position
	await touch(0,true,Vector2(185,625))
	await frames(4)
	check(game.player.position.x>start.x,"Touch movement uses a real held right button")
	await touch(1,true,Vector2(1190,450))
	check(game.player.dash_time>0 and Input.is_action_pressed("sprint"),"A second finger starts dash and holding it enables running")
	await touch(2,true,Vector2(1190,565))
	check(game.player.velocity.y<0 and game.player.dash_time>0,"A third touch can jump while dashing and moving")
	await touch(2,false,Vector2(1190,565))
	await touch(1,false,Vector2(1190,450))
	await touch(0,false,Vector2(185,625))
	check(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("sprint"),"Lifting fingers releases movement and sprint")
	await frames(65)
	game.player.reset_health()
	await touch(0,true,Vector2(1065,515))
	check(game.player.is_attacking,"Touch attack reaches gameplay input")
	await touch(0,false,Vector2(1065,515))
	await frames(40)
	game.player.reset_health()
	await touch(0,true,Vector2(1065,620))
	check(game.player.parry_time>0,"Touch parry opens the parry window")
	await touch(0,false,Vector2(1065,620))
	game.player.reset_health()
	await touch(0,true,Vector2(185,625))
	game._show_pause()
	await frames(3)
	check(not controls.pad.visible and not Input.is_action_pressed("move_right"),"Opening a modal clears held touches")
	await touch(0,false,Vector2(185,625))
	game._close_overlay()
	game.queue_free()
	await frames(3)
	print("DEVICE_CONTROLS failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

extends Node2D
var failures := 0
var player: CharacterBody2D

func _ready() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame

func _run() -> void:
	preload("res://tests/test_session.gd").isolate("jaka_combat.gd")
	GameState.upgrade_levels.heart = 2
	GameState.reset_stage()
	var floor_body := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(4000, 100)
	collider.shape = shape
	floor_body.position = Vector2(1500, 620)
	floor_body.add_child(collider)
	add_child(floor_body)
	player = preload("res://player.tscn").instantiate()
	player.position = Vector2(400,570)
	add_child(player)
	await frames(6)
	check(player.anim.sprite_frames.get_frame_texture("idle",0).resource_path.ends_with("/idle_01.png"),"Idle uses the requested standing Jaka artwork")
	check(player.anim.sprite_frames.get_frame_count("keris_attack")==6 and player.anim.sprite_frames.get_frame_texture("keris_attack",0).resource_path.ends_with("/attack_01.png"),"Normal attack uses six dedicated frames from the latest Attack sheet")
	check(player.perform_parry(), "Parry starts")
	await frames(12)
	check(player.anim.animation=="parry" and player.anim.frame==0, "Frame one stays held without a hit")
	await frames(14)
	check(player.parry_time==0 and player.parry_cooldown>1.9, "Missed parry starts the two-second cooldown after its window")
	check(not player.perform_parry(), "Cooldown blocks another attempt")
	await frames(121)
	check(player.perform_parry(), "Parry returns after cooldown")
	player.take_damage(1, player.position.x+30, true)
	check(player.health==5 and player.stance==1 and player.anim.frame==1, "First success blocks damage, adds stance and starts reaction")
	await frames(8)
	check(player.anim.frame>1, "Success advances through reaction frames")
	for index in range(4):
		check(player.perform_parry(), "Success permits another parry without cooldown")
		player.take_damage(1, player.position.x+30, true)
	check(player.stance==5 and player.health==5, "The fifth successful parry is still safe")
	check(not player.perform_parry() and is_equal_approx(player.stun_time,2.0), "Attempt six causes two seconds of stun")
	var before: Vector2 = player.position
	Input.action_press("move_right")
	player.perform_attack()
	check(not player.is_attacking and not player.perform_heal() and not player.perform_ultimate(), "Stun blocks skills")
	await frames(30)
	check(absf(player.position.x-before.x)<1, "Stun blocks movement")
	Input.action_release("move_right")
	await frames(31)
	check(player.stance==4 and player.stun_time>0.9, "One stance point recovers after one second")
	await frames(61)
	check(player.stance==3 and player.stun_time==0, "Recovery continues through stun without an instant reset")
	await frames(181)
	check(player.stance==0, "Remaining stance recovers one point per second")
	player.reset_health()
	player.perform_parry()
	player.take_damage(1, player.position.x+30, false)
	check(player.health==4 and player.parry_reaction==0, "Unparryable attacks still damage the player")
	await frames(70)
	player.reset_health()
	player.perform_parry()
	var shot := preload("res://scripts/patrol_shot.gd").new()
	shot.position = player.position+Vector2(95,-66)
	shot.direction = -1
	add_child(shot)
	await frames(12)
	check(not is_instance_valid(shot) and player.health==5 and player.stance==1, "A live ranged projectile can be parried")
	player.reset_health()
	Input.action_press("move_right")
	await frames(8)
	check(player.anim.animation=="walk" and is_equal_approx(player.velocity.x,160), "Walking uses the new animation")
	Input.action_press("sprint")
	await frames(8)
	check(player.anim.animation=="run" and is_equal_approx(player.velocity.x,260), "Holding Shift runs")
	Input.action_release("sprint")
	await frames(4)
	check(player.anim.animation=="walk" and is_equal_approx(player.velocity.x,160), "Releasing Shift walks again")
	Input.action_release("move_right")
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	await frames(10)
	var landing_frames := 0
	while not player.is_on_floor() and landing_frames < 70:
		await frames(1)
		landing_frames += 1
	check(player.is_on_floor() and not player.effects.particles.is_empty(), "Landing produces dust")
	for i in range(20):
		player.effects.burst(player.position,30,Color.WHITE)
	check(player.effects.particles.size()<=player.effects.LIMIT, "Particles have a bounded budget")
	for i in range(20): player.effects.impact(player.position,Color.WHITE)
	check(player.effects.flashes.size()<=player.effects.FLASH_LIMIT,"Impact flashes have a bounded budget")
	await frames(55)
	check(player.effects.flashes.is_empty() and player.effects.particles.is_empty(),"Burst and impact pools expire after combat")
	player.effects.dust(player.position,1.5)
	player.effects.impact(player.position)
	player.reset_health()
	check(player.effects.particles.is_empty() and player.effects.flashes.is_empty(),"Retry clears lingering particles and flashes")
	print("JAKA_COMBAT failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

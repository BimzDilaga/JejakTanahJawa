extends Node
var game: Node
var failures := 0
var capture_dir := ""
func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screenshots="): capture_dir=a.trim_prefix("--screenshots=")
	_run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures+=1
		push_error(message)
func frames(n: int) -> void:
	for i in range(n): await get_tree().physics_frame
func dialogue() -> void:
	var safety:=0
	while GameState.dialogue_active and safety<100:
		game.advance_dialogue()
		safety+=1
	await frames(3)
func walk(x: float) -> void:
	var action := "move_right" if x>game.player.position.x else "move_left"
	Input.action_press(action)
	var safety:=0
	while absf(game.player.position.x-x)>8 and safety<800:
		await frames(1)
		safety+=1
	Input.action_release(action)
	await frames(2)
	check(safety<800,"Walking route unreachable at "+str(x))
func hop(x: float) -> void:
	Input.action_press("jump")
	await frames(1)
	Input.action_release("jump")
	await walk(x)
	await frames(45)
	check(game.player.is_on_floor(),"Jump did not land at "+str(x))
func shot(name: String) -> void:
	if capture_dir!="":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture_dir.path_join(name+".png"))
func traverse_patrol() -> void:
	var ticks := 0
	while game.player.position.x < 11745 and not game.player.dead and ticks < 12000:
		Input.action_release("move_left")
		Input.action_release("move_right")
		var closest: Node2D = null
		var distance := 230.0
		for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
			var delta: Vector2 = enemy.position-game.player.position
			if absf(delta.y)<90 and absf(delta.x)<distance:
				closest=enemy
				distance=absf(delta.x)
		for projectile: Node2D in get_tree().get_nodes_in_group("patrol_shots"):
			var offset: Vector2 = game.player.position - Vector2(0, 55) - projectile.position
			if absf(offset.y) < 34.0 and offset.x * projectile.get("direction") >= 0.0 and absf(offset.x) < 115.0:
				game.player.perform_parry()
		if game.player.health < 4 and distance > 150.0:
			game.player.perform_heal()
		if closest != null and distance<135:
			game.player.facing=1 if closest.position.x>game.player.position.x else -1
			# One deliberate tap per swing; calling every frame would buffer a full combo.
			if not game.player.perform_ultimate() and not game.player.is_attacking:
				game.player.perform_attack()
			if distance<95:
				Input.action_press("move_left" if game.player.facing==1 else "move_right")
		else:
			Input.action_press("move_right")
		await frames(1)
		ticks+=1
	Input.action_release("move_left")
	Input.action_release("move_right")
	check(not game.player.dead and ticks<12000,"Entire patrol route traversed with normal health and attacks")
	print("PATROL_ROUTE seconds=",float(ticks)/60.0," health=",game.player.health," defeated=",game.defeated_count)
func _run() -> void:
	preload("res://tests/test_session.gd").isolate("chapter_two_smoke.gd")
	GameState.upgrade_levels.heart = 2
	game=load("res://bab_jalur_perlawanan.tscn").instantiate()
	add_child(game)
	await frames(6)
	await dialogue()
	var walkers: Array = game.world.find_children("WargaBerjalan*", "", true, false)
	check(walkers.size() == 1 and walkers[0].position.x < 1900, "Only the village edge has a wandering NPC; forest and patrol stay empty")
	check(game.player.world_right>12000,"Player bounds extended")
	Input.action_release("sprint")
	Input.action_press("move_right")
	await frames(4)
	check(is_equal_approx(game.player.velocity.x, 160.0), "Default movement uses walking speed")
	check(game.player.anim.animation == "walk", "Default movement uses walking frames")
	Input.action_press("sprint")
	await frames(4)
	check(is_equal_approx(game.player.velocity.x, 260.0), "Holding Shift uses running speed")
	check(game.player.anim.animation == "run", "Holding Shift uses running frames")
	Input.action_release("sprint")
	await frames(4)
	check(is_equal_approx(game.player.velocity.x, 160.0), "Releasing Shift immediately restores walking")
	Input.action_release("move_right")
	Input.action_press("sprint") # Existing parkour route is tested at running speed.
	await walk(650)
	game._interact("sari")
	game.advance_dialogue()
	game.advance_dialogue()
	check(game.choice_active,"Sari offers response choices")
	check(game.portrait.texture.atlas.resource_path==game.SARI_IMAGE,"Sari uses the same portrait in Chapter 2")
	game.typing=float(game.dialogue_label.get_total_character_count())
	game.dialogue_label.visible_characters=int(game.typing)
	await frames(2)
	await shot("dialogue")
	game._choose(1)
	await dialogue()
	check(game.mission==1,"Village objective")
	game._show_pause()
	check(get_tree().paused,"Chapter 2 pauses")
	game._close_overlay()
	game._show_journal()
	check(game.overlay.visible,"History journal opens")
	game._close_overlay()
	await walk(2370)
	game._interact("bridge")
	await dialogue()
	await shot("bridge")
	await walk(2470)
	await hop(2630)
	await walk(2690)
	await hop(2820)
	await walk(2910)
	await hop(3060)
	await walk(3130)
	await hop(3290)
	check(game.crossed and game.mission==2,"Alternate crossing completed with real movement")
	game.player.position=Vector2(3000,850)
	await frames(3)
	check(game.player.position.x>3250 and game.mission==2,"Falling returns to crossing checkpoint with progress")
	await walk(4480)
	game._interact("lasmi")
	await dialogue()
	check(game.mission==3,"Aid mission offered")
	game._interact("deliver")
	check(game.mission==3,"Cannot deliver without supply")
	await walk(4820)
	await hop(4950)
	await walk(5000)
	await hop(5180)
	game._interact("supply")
	check(game.carried_supply,"Supply collected on upper ledge")
	check(GameState.heal_stock==1,"Supply pickup grants one heal")
	await shot("supply")
	await walk(5940)
	await frames(40)
	game._interact("deliver")
	await dialogue()
	check(game.delivered and game.mission==4,"Aid delivered")
	await walk(6600)
	await frames(6)
	check(game.checkpoint_reached,"Risk checkpoint")
	check(get_tree().get_nodes_in_group("enemies").size()==10,"Exactly ten soldiers spawn in Chapter 2")
	await shot("checkpoint")
	# Test that real combat deals damage, respects invulnerability, and can defeat an enemy.
	var enemy: Node=game.soldiers[0]
	for other: Node in game.soldiers:
		other.active = other == enemy
	game.player.position=enemy.position-Vector2(325,0)
	await frames(100)
	check(game.player.health<5,"A soldier can hit Jaka from beyond melee range")
	enemy.active = false
	game.player.reset_health()
	check(game.player.perform_parry(),"Parry starts when ready")
	check(not game.player.perform_parry(),"An active parry window cannot be restarted")
	game.player.take_damage(1, game.player.position.x + 10.0, true)
	check(game.player.health==5,"Parry blocks melee damage within the active window")
	check(game.player.parry_cooldown==0.0 and game.player.perform_parry(),"Successful parry allows an immediate new attempt")
	var shot_scene = load("res://scripts/patrol_shot.gd")
	var projectile: Node2D = shot_scene.new()
	projectile.direction = -1
	projectile.position = game.player.position + Vector2(100, -66)
	game.world.add_child(projectile)
	await frames(12)
	check(not is_instance_valid(projectile) and game.player.health==5,"Parry blocks a live projectile")
	await frames(14)
	game.player.take_damage(1, game.player.position.x + 10.0, true)
	check(game.player.health==4,"Damage applies after the parry window closes")
	check(game.player.perform_heal() and game.player.health==5,"Heal restores one heart")
	check(GameState.heal_stock==0,"Using heal consumes one item")
	game.player.invulnerable_time = 0.0
	game.player.take_damage(1, game.player.position.x)
	await frames(46)
	check(not game.player.perform_heal(),"Heal requires an item even with missing health")
	game.player.reset_health()
	enemy.active = true
	game.player.position=enemy.position-Vector2(60,0)
	await frames(110)
	check(game.player.health<5,"Enemy can damage player")
	game.player.reset_health()
	for hit in range(3):
		game.player.position=enemy.position-Vector2(120,0)
		game.player.facing=1
		game.player.perform_attack()
		await frames(35)
	check(game.defeated_count==1,"Enemy defeated exactly once")
	check(game.player.ultimate_charge==3,"Landed attacks charge the ultimate")
	var dash_target: Node = game.soldiers[1]
	dash_target.active = true
	dash_target.cooldown = 9.0
	game.player.position = dash_target.position - Vector2(160, 0)
	game.player.facing = 1
	game.player.ultimate_charge = game.player.ULTIMATE_HITS
	check(game.player.perform_ultimate(),"A full charge starts the ultimate")
	await frames(20)
	check(dash_target.health==1 and dash_target.stun_time>0.0 and game.player.ultimate_charge==0,"Ultimate dash hits once, stuns, and spends its charge")
	game.player.invulnerable_time=0
	game.player.take_damage(5,game.player.position.x-1)
	await frames(3)
	check(game.stage==game.Stage.FAILED,"Death offers checkpoint")
	game._respawn()
	await frames(5)
	check(game.player.health==5 and game.delivered,"Checkpoint retains completed aid")
	check(get_tree().get_nodes_in_group("enemies").size()==10,"Retry restores exactly ten soldiers without duplicate patrols")
	await walk(6880)
	await hop(7030)
	await walk(7080)
	await hop(7230)
	await walk(7270)
	await hop(7400)
	check(game.player.position.y<450,"Elevated patrol bypass reachable")
	await shot("patrol")
	await traverse_patrol()
	await frames(5)
	check(game.mission==5,"Patrol exit objective")
	check(game.ravine_checkpoint_reached,"Ravine has a checkpoint")
	check(GameState.defeats_toward_heal==(game.defeated_count+1)%7,"Patrol defeats count toward the next heal")
	await walk(11890)
	for jump in [[11890, 12000], [12102, 12232], [12351, 12482], [12609, 12765], [12836, 12967], [13085, 13227], [13350, 13490], [13615, 13760]]:
		await walk(jump[0])
		await hop(jump[1])
	await walk(14350)
	game._interact("guide")
	await dialogue()
	check(game.mission==6,"Guide opens final path")
	await walk(14785)
	Input.action_press("move_right")
	await frames(12)
	Input.action_release("move_right")
	check(game.stage==game.Stage.TRANSITION,"Final path starts cinematic")
	await dialogue()
	await frames(45)
	check(game.stage==game.Stage.COMPLETE,"Chapter ends on Selarong handoff")
	await shot("ending")
	GameState.reset_campaign()
	for defeat in range(6):
		check(not GameState.award_patrol_defeat(),"A partial group does not grant a heal")
	check(GameState.award_patrol_defeat() and GameState.heal_stock==1,"The seventh defeat grants one heal")
	print("CHAPTER_TWO_SMOKE failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

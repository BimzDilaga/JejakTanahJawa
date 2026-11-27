extends Node
var failures := 0
var game: Node
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func dialogue() -> void:
	var safety := 0
	while GameState.dialogue_active and safety<100:
		if game.choice_active: game._choose(0)
		else: game.advance_dialogue()
		safety += 1
	await frames(4)
	check(safety<100,"Dialogue finishes")
func _run() -> void:
	preload("res://tests/test_session.gd").isolate("campaign_persistence.gd")
	var normal_slot: String = GameState.save_path
	GameState.save_path = "user://qa/campaign-test.json"
	GameState.reset_campaign(true)
	check(not GameState.has_save(),"A cleared slot has no continue game")
	game = load("res://bab_jalur_perlawanan.tscn").instantiate()
	add_child(game)
	await frames(6)
	await dialogue()
	GameState.buy_upgrade("heart")
	GameState.buy_upgrade("attack")
	GameState.award_upgrade_defeat()
	GameState.award_upgrade_defeat()
	game.mission = 4
	game.delivered = true
	game.carried_supply = false
	game.checkpoint_reached = true
	game.checkpoint = Vector2(6580,570)
	game.checkpoint_name = "Sebelum patroli"
	game._spawn_patrol()
	game.soldiers[0].take_damage(999,0)
	game.player.position = Vector2(6580,570)
	await frames(4)
	game.player.health = 2
	game.player.stamina = 85
	game.player.ultimate_charge = 3
	game.night_events.rumor_learned = true
	GameState.heal_stock = 2
	GameState.time_of_day = 0.875
	GameState.night_boss_defeated.buto = true
	GameState.set_objective("Seberangi jalur patroli tanpa wajib bertarung.")
	check(GameState.save_campaign(game),"Campaign writes a valid disk save")
	var points: int = GameState.upgrade_points
	game.queue_free()
	await frames(4)
	GameState.reset_campaign()
	check(GameState.load_campaign(),"Save can be loaded after all in-memory progress is reset")
	check(GameState.upgrade_points==points and GameState.upgrade_levels.heart==1 and GameState.upgrade_levels.attack==1,"Purchases and enemy reward survive reload")
	check(GameState.heal_stock==2 and GameState.night_boss_defeated.buto and GameState.unlocked_chapter==2,"Supplies, boss victory and progressive unlock survive reload")
	GameState.pending_restore = 2
	game = load("res://bab_jalur_perlawanan.tscn").instantiate()
	add_child(game)
	await frames(8)
	check(not GameState.dialogue_active and game.mission==4 and game.delivered and game.checkpoint_reached,"Loading restores the quest instead of restarting its intro")
	check(game.player.health==2 and game.player.max_health==4 and game.player.ultimate_charge==3,"Loading preserves current HP and ultimate charge")
	check(game.player.position.distance_to(Vector2(6580,570))<3 and game.night_events.rumor_learned,"Position/checkpoint and learned rumor are restored")
	check(game.soldiers.size()==10 and game.soldiers[0].health==3 and not game.soldiers[0].dead,"Exactly ten regular patrol enemies reset when a chapter reloads")
	game.journey.show_map()
	var buttons: Array = game.journey.map_root.find_children("*","Button",true,false)
	check(get_tree().paused and buttons.size()==7 and not buttons[0].disabled and not buttons[1].disabled and buttons[2].disabled and buttons[4].disabled,"Map locks later chapters and exposes only visited regions")
	game.journey.close_map()
	check(not get_tree().paused,"Closing the map resumes gameplay")
	# Save two revisions, corrupt only the latest; previous valid progress is recovered.
	check(GameState.save_campaign(game),"Write first backup revision")
	GameState.upgrade_points = points+2
	check(GameState.save_campaign(game),"Write second revision")
	var corrupt := FileAccess.open(GameState.save_path,FileAccess.WRITE)
	corrupt.store_string("{ interrupted")
	corrupt.close()
	check(GameState.load_campaign() and GameState.upgrade_points==points,"A corrupt primary falls back to the previous checksum-verified revision")
	remove_child(game)
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	GameState.travel_to(1,game)
	await frames(60)
	game = get_tree().current_scene
	await dialogue()
	check(GameState.chapter_id(game)==1 and game.player.position.distance_to(game.upgrade_hut.hut.position+Vector2(65,0))<5,"Teleport opens the requested region at its hut")
	check(game.player.health==2 and GameState.night_boss_defeated.buto and GameState.upgrade_points==points,"Teleport carries HP and permanent progression without free healing")
	GameState.travel_to(2,game)
	await frames(60)
	game = get_tree().current_scene
	check(game.mission==4 and game.soldiers.size()==10 and game.soldiers[0].health==3,"Returning by map retains the quest and repopulates exactly ten regular enemies")
	GameState.night_boss_defeated = {"buto":true,"banaspati":true,"headless":true,"commander":true}
	GameState.unlocked_endings.jejak = true
	check(GameState.save_campaign(game),"Ending and victory progress can be saved")
	GameState.reset_campaign()
	check(GameState.load_campaign() and GameState.secret_ending_ready() and GameState.unlocked_endings.jejak,"All three boss requirements and unlocked ending persist")
	get_tree().current_scene = null
	game.queue_free()
	await frames(4)
	GameState.reset_campaign(true)
	check(not GameState.has_save() and GameState.upgrade_points==600 and GameState.player_max_health()==3,"Explicit new-game reset removes the save and returns demo levels to zero")
	GameState.save_path = normal_slot
	print("CAMPAIGN_PERSISTENCE failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

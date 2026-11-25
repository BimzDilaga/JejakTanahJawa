extends Node
var failures := 0
func _ready() -> void: _run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	preload("res://tests/test_session.gd").isolate("final_boss_combat.gd")
	GameState.reset_campaign()
	for kind in ["headless","commander"]:
		GameState.boss_trial_kind = kind
		var arena: Node = load("res://boss_trial.tscn").instantiate()
		add_child(arena)
		await frames(70)
		var boss: Node = arena.boss
		boss.set_physics_process(false)
		for animation in ["idle","walk","run","spawn","hurt","light","heavy","stagger","death"]:
			check(boss.sprite.sprite_frames.has_animation(animation) and boss.sprite.sprite_frames.get_frame_count(animation)>0,"Prepared animation exists: "+kind+"/"+animation)
		for chain in range(1,4):
			boss.start_combo(chain)
			check(boss.combo.size()==(4 if chain==2 else 5),"Chain length for "+kind+"/"+str(chain))
			for strike in boss.combo: check(boss.sprite.sprite_frames.has_animation(str(strike.animation)),"Every chained strike has usable art")
		if kind=="commander":
			for animation in ["rapid","flintshot","finalsalvo","reload"]:
				check(boss.sprite.sprite_frames.get_frame_count(animation)==(8 if animation=="reload" else 10),"Final boss retains original shots and new reload")
			arena.player.position = Vector2(500,570)
			boss.position = Vector2(950,570)
			boss.attack = {"animation":"flintshot","effect":"flintshot","heavy":false,"aim_point":arena.player.position}
			boss._strike()
			var hazards: Array = get_tree().get_nodes_in_group("trial_hazards")
			check(hazards.size()==1 and hazards[0].parryable and hazards[0].motion.x<0,"Commander fires a visible parryable projectile toward the locked target")
			arena.player.position.x = 1300
			check(hazards[0].motion.x<0,"Shot does not home after the player moves")
			arena._clear_hazards()
			await frames(2)
			boss.attack.effect = "finalsalvo"
			boss._strike()
			hazards = get_tree().get_nodes_in_group("trial_hazards")
			check(hazards.size()==5 and hazards[4].warning>hazards[0].warning,"Final salvo has five staggered shots rather than an instant unavoidable hit")
			arena._clear_hazards()
			boss.shots_since_reload = 6
			boss._set_state("recovery")
			check(boss.state=="reload","Repeated shots expose a reload opening")
			var hp: int = boss.health
			check(boss.take_damage(1,0) and boss.health==hp-1,"Reload leaves the commander vulnerable")
			boss.set_physics_process(true)
			await frames(125)
			check(boss.shots_since_reload==0 and boss.state!="reload","Reload finishes and resets the firing counter")
			boss.take_damage(999,0)
			await frames(240)
			check(boss.phase==2 and boss.tempo()>1.3 and boss.health==boss.max_health,"Commander phase two restores HP with a faster tempo")
			boss.set_physics_process(false)
			boss.sequence = 0
			boss._choose_attack()
			check(boss.current_combo==3,"Phase two opens with the ultimate chain")
		else:
			var headless_height: float = boss.sprite.sprite_frames.get_frame_texture("idle",0).get_image().get_used_rect().size.y*boss.sprite.scale.y
			var jaka_height: float = arena.player.anim.sprite_frames.get_frame_texture("idle",0).get_image().get_used_rect().size.y
			check(headless_height>jaka_height and headless_height<=jaka_height*1.25,"Headless is only slightly taller than Jaka")
			check(is_equal_approx(boss.sprite.position.y+144*boss.sprite.scale.y,0),"Smaller Headless keeps its boots on the ground")
			check(arena.sounds.size()==12 and arena.boss_music.stream.resource_path.ends_with("headless-smoke-and-bronze.ogg"),"Headless has its own complete sound pack and music")
			check(boss.invulnerable and boss.attack.effect=="smoke_step","The ultimate chain clearly begins with a smoke step")
			var aim: Vector2 = boss.attack.aim_point
			var direction: int = boss.facing
			arena.player.position.x += 300
			boss._strike()
			check(is_equal_approx(boss.position.x,clampf(aim.x+direction*155,70,arena.ground_boss_limit())),"Smoke step uses its telegraphed target instead of following player movement")
			boss._set_state("recovery")
			check(not boss.invulnerable,"Headless becomes vulnerable after the smoke step")
			for i in range(4): boss.on_parried()
			check(boss.state=="stagger_in","Headless has its own stance break")
		arena.queue_free()
		await frames(4)
	for key in ["swing_1","swing_2","swing_3"]:
		var audio := preload("res://scripts/combat_audio.gd").new()
		add_child(audio)
		check(audio.streams.has(key) and audio.streams[key].get_length()>0.1,"Temporary Jaka swing SFX decodes: "+key)
		audio.queue_free()
	print("FINAL_BOSS_COMBAT failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

extends Node
var game: Node
var failures := 0
var capture_dir := ""

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--screenshots="):
			capture_dir = argument.trim_prefix("--screenshots=")
	if not capture_dir.is_empty(): DirAccess.make_dir_recursive_absolute(capture_dir)
	_run.call_deferred()

func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func coverage(label: String) -> void:
	var first := true
	var filled := Rect2()
	for tile in game.depth_background.get_children():
		var bounds := Rect2(tile.global_position,tile.texture.get_size()*tile.scale)
		filled = bounds if first else filled.merge(bounds)
		first = false
	var size: Vector2 = get_viewport().get_visible_rect().size/game.camera.zoom
	var visible := Rect2(game.camera.get_screen_center_position()-size/2,size)
	check(filled.encloses(visible),"Opaque depth covers the full camera at "+label)
	# Joining tiles must overlap, rather than leaving a subpixel seam.
	var tiles: Array = game.depth_background.get_children()
	for index in range(1,tiles.size()):
		var right: float = tiles[index-1].global_position.x+tiles[index-1].texture.get_width()*tiles[index-1].scale.x
		check(right>tiles[index].global_position.x,"Depth tiles overlap at "+label)

func shot(label: String) -> void:
	if capture_dir.is_empty(): return
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(capture_dir.path_join(label+".png"))==OK,"Save "+label)

func _run() -> void:
	preload("res://tests/test_session.gd").isolate("selarong_visual_audit.gd")
	GameState.reset_campaign()
	game = load("res://bab_selarong.tscn").instantiate()
	add_child(game)
	await frames(5)
	while GameState.dialogue_active: game.advance_dialogue()
	game.player.controls_enabled = false
	game.player.set_physics_process(false)
	game.day_night.clock_enabled = false
	game.notice_time = 0
	game.notice.hide()
	check(game.telescope.texture is AtlasTexture,"Telescope uses generated sprite art")
	check(game.world.has_node("Shelter") and game.world.has_node("UpgradeHut") and game.upgrade_hut.hut.get_child_count()==1,"Upgrade interaction reuses the detailed shelter without duplicate art")
	var panorama: Texture2D = game.depth_background.get_child(0).texture
	check(panorama.get_image().detect_alpha()==Image.ALPHA_NONE,"Depth panorama contains no transparent holes")
	var ledges := get_tree().get_nodes_in_group("selarong_ledges")
	check(ledges.size()==4,"All three parkour ledges and lookout use stone art")
	for ledge in ledges:
		var body: StaticBody2D = ledge.get_meta("collision_body")
		var collision: CollisionShape2D = body.get_child(0)
		var top: float = body.global_position.y-collision.shape.size.y/2
		var profile: Dictionary = game.art[ledge.get_meta("art_kind")]
		var art_top: float = ledge.global_position.y+float(profile.surface_from_top)*ledge.scale.y
		check(absf(top-art_top)<0.1,"Visible moss cap matches collision top")
	for phase in range(4):
		GameState.time_of_day = phase*0.25+0.125
		var places := [Vector2(260,570),Vector2(1120,570),Vector2(1380,525),Vector2(1550,465),Vector2(1740,520),Vector2(2140,570),Vector2(2780,570),Vector2(3540,570),Vector2(4000,570),Vector2(4440,510),Vector2(4870,570)] if phase==1 else [Vector2(1550,465),Vector2(3540,570),Vector2(4440,510)]
		for at in places:
			game.mission = 2 if at.x>4150 else (1 if at.x>=2140 else 0)
			GameState.set_objective("Amati jalur desa dengan teropong di kanan." if game.mission==2 else ("Temui Diponegoro di kawasan gua." if game.mission==1 else "Temui penjaga di kawasan gua Selarong."))
			game.player.position = at
			game.cat.position = at+Vector2(-70,-56)
			game.camera.position.x = clampf(at.x+150,game.CAMERA_HALF_WIDTH,game.LENGTH-game.CAMERA_HALF_WIDTH)
			game.camera.force_update_scroll()
			await frames(4)
			var label := "%s-%d" % [game.day_night.phase_name(GameState.time_of_day).to_lower(),int(at.x)]
			coverage(label)
			await shot(label)
	game.queue_free()
	await frames(3)
	print("SELARONG_VISUAL_AUDIT failures=",failures)
	get_tree().quit(0 if failures==0 else 1)

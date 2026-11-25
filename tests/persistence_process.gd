extends SceneTree
var failures := 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.save_path = "user://qa/separate-process.json"
	var mode := "read" if "read" in OS.get_cmdline_user_args() else "write"
	if mode=="write":
		state.reset_campaign(true)
		var chapter: Node = load("res://bab_desa_terdampak.tscn").instantiate()
		root.add_child(chapter)
		for i in range(8): await physics_frame
		while state.dialogue_active: chapter.advance_dialogue()
		state.buy_upgrade("heart")
		chapter.mission = 2
		chapter.player.health = 2
		chapter.night_events.rumor_learned = true
		state.night_boss_defeated = {"buto":true,"banaspati":true,"headless":true}
		state.heal_stock = 4
		check(state.save_campaign(chapter),"Writer process persists the campaign")
		chapter.queue_free()
	else:
		check(state.upgrade_points==600 and state.upgrade_levels.heart==0,"Reader begins with fresh in-memory state")
		check(state.load_campaign(),"A separate Godot process loads the written slot")
		check(state.upgrade_points==598 and state.upgrade_levels.heart==1 and state.heal_stock==4,"Stats and supplies survive process termination")
		check(state.last_chapter==4 and int(state.chapter_records["4"].fields.mission)==2 and state.chapter_records["4"].rumor,"Chapter, quest and rumor survive process termination")
		check(state.night_boss_defeated.size()==3,"All urban victories survive process termination")
	print("PERSISTENCE_PROCESS ",mode," failures=",failures)
	quit(0 if failures==0 else 1)

extends Node

signal objective_updated(text: String)
signal dialogue_started
signal dialogue_ended
signal stats_changed
signal points_changed
signal save_completed(success: bool)
const SaveStore = preload("res://scripts/campaign_save.gd")
const CHAPTER_PATHS := ["res://bab_tegalrejo.tscn","res://bab_jalur_perlawanan.tscn","res://bab_selarong.tscn","res://bab_desa_terdampak.tscn","res://bab_magelang.tscn"]
const CHAPTER_NAMES := ["Tegalrejo","Jalur Hutan","Selarong","Desa Terdampak","Magelang"]
const RECORD_FIELDS := ["mission","facts_unlocked","checkpoint","checkpoint_name","checkpoint_reached","ravine_checkpoint_reached","carried_supply","delivered","crossed","patrol_started","defeated_count"]
var save_path := "user://campaign-v1.json"
var campaign_active := false
var unlocked_chapter := 1
var last_chapter := 1
var completed_chapters: Array[int] = []
var chapter_records: Dictionary = {}
var active_story: Node
var pending_restore := 0
var pending_arrival := false
var pending_vitals: Dictionary = {}
var _transition_busy := false
var progression: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/progression.json"))
var upgrade_levels := {"heart":0,"attack":0,"speed":0,"stamina":0}
var upgrade_points := 600
var upgrade_defeats := 0
var story_notes: Dictionary = {}
var unlocked_endings: Dictionary = {}

var start_on_load: bool = false
var dialogue_active: bool = false
var ending_started: bool = false
var objective_completed: bool = false
var supply_checked: int = 0
var enemies_defeated: int = 0
var objective: String = ""
var heal_stock := 0
var defeats_toward_heal := 0
var aid_heal_claimed := false
const DAY_START := 0.625 # Afternoon, matching the prologue's approaching evening.
var time_of_day := DAY_START
var boss_trial_kind := "buto"
var night_boss_defeated: Dictionary = {}
var encounter_chapter: Node
var encounter_snapshot: Dictionary = {}
const ENCOUNTER_FIELDS := ["start_on_load","dialogue_active","ending_started","objective_completed","supply_checked","enemies_defeated","objective","heal_stock","defeats_toward_heal","aid_heal_claimed","time_of_day"]
@export_range(30.0,3600.0,1.0) var day_cycle_seconds := 240.0

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST: save_campaign()

func advance_day_time(delta: float) -> void:
	time_of_day = fposmod(time_of_day + maxf(delta,0.0) / maxf(day_cycle_seconds,1.0),1.0)

func claim_aid_heal() -> bool:
	if aid_heal_claimed:
		return false
	aid_heal_claimed = true
	heal_stock += 1
	return true

func award_patrol_defeat() -> bool:
	defeats_toward_heal += 1
	if defeats_toward_heal < 7:
		return false
	defeats_toward_heal = 0
	heal_stock += 1
	return true

func reset_campaign(clear_persistent := false) -> void:
	if clear_persistent: SaveStore.clear_slot(save_path)
	campaign_active = false
	unlocked_chapter = 1
	last_chapter = 1
	completed_chapters.clear()
	chapter_records.clear()
	pending_restore = 0
	pending_arrival = false
	pending_vitals.clear()
	upgrade_points = int(progression.demo_points)
	upgrade_defeats = 0
	upgrade_levels = {"heart":0,"attack":0,"speed":0,"stamina":0}
	story_notes.clear()
	unlocked_endings.clear()
	stats_changed.emit()
	points_changed.emit()
	night_boss_defeated.clear()
	time_of_day = DAY_START
	heal_stock = 0
	defeats_toward_heal = 0
	aid_heal_claimed = false

func player_max_health() -> int:
	return mini(int(progression.maximum_hearts),int(progression.base_hearts)+int(upgrade_levels.heart))

func player_attack() -> int:
	return 1+int(upgrade_levels.attack)*int(progression.attack_per_level)

func player_max_stamina() -> float:
	return float(progression.base_stamina)+int(upgrade_levels.stamina)*float(progression.stamina_per_level)

func upgrade_cost(attribute: String) -> int:
	if not upgrade_levels.has(attribute): return -1
	if attribute=="heart" and player_max_health()>=int(progression.maximum_hearts): return -1
	return int(pow(2,mini(31,int(upgrade_levels[attribute])+1)))

func buy_upgrade(attribute: String) -> bool:
	var cost := upgrade_cost(attribute)
	if cost<0 or upgrade_points<cost: return false
	upgrade_points -= cost
	upgrade_levels[attribute] += 1
	stats_changed.emit()
	points_changed.emit()
	request_save()
	return true

func award_upgrade_defeat() -> bool:
	upgrade_defeats += 1
	var earned := upgrade_defeats>=int(progression.defeats_per_point)
	if earned:
		upgrade_defeats -= int(progression.defeats_per_point)
		upgrade_points += 1
	points_changed.emit()
	request_save()
	return earned

func secret_ending_ready() -> bool:
	return night_boss_defeated.get("buto",false) and night_boss_defeated.get("banaspati",false) and night_boss_defeated.get("headless",false) and night_boss_defeated.get("commander",false)

func hold_encounter_origin(chapter: Node) -> void:
	begin_chapter(chapter)
	save_campaign(chapter)
	encounter_chapter = chapter
	encounter_snapshot.clear()
	for field in ENCOUNTER_FIELDS: encounter_snapshot[field] = get(field)

func return_from_encounter(arena: Node) -> bool:
	if not is_instance_valid(encounter_chapter): return false
	var tree := arena.get_tree()
	var chapter := encounter_chapter
	var snapshot := encounter_snapshot.duplicate()
	encounter_chapter = null
	encounter_snapshot.clear()
	tree.current_scene = null
	arena.get_parent().remove_child(arena)
	tree.root.add_child(chapter)
	tree.current_scene = chapter
	for field in snapshot: set(field,snapshot[field])
	objective_updated.emit(objective)
	arena.queue_free()
	return true

func _exit_tree() -> void:
	if is_instance_valid(encounter_chapter) and encounter_chapter.get_parent()==null:
		encounter_chapter.free()

func set_objective(text: String, is_done: bool = false) -> void:
	objective = text
	objective_completed = is_done
	objective_updated.emit(text)

func add_supply_check() -> void:
	supply_checked += 1
	set_objective("Periksa perbekalan (%d/2)" % supply_checked)

func add_enemy_defeated(target_total: int = 2) -> void:
	enemies_defeated = mini(enemies_defeated + 1, target_total)
	if enemies_defeated < target_total:
		set_objective("Hadapi tentara Belanda (%d/%d)" % [enemies_defeated, target_total])
	else:
		set_objective("Jalur terbuka. Cari jalan keluar!", true)

func reset_stage() -> void:
	dialogue_active = false
	ending_started = false
	objective_completed = false
	supply_checked = 0
	enemies_defeated = 0
	objective = ""

func chapter_id(scene: Node) -> int:
	if not is_instance_valid(scene): return 0
	return ["chapter_one.gd","chapter_two.gd","chapter_three.gd","chapter_four.gd","chapter_five.gd"].find(scene.get_script().resource_path.get_file())+1

func begin_chapter(scene: Node) -> void:
	var id := chapter_id(scene)
	if id==0: return
	active_story = scene
	campaign_active = true
	last_chapter = id
	unlocked_chapter = maxi(unlocked_chapter,id)

func record_chapter(scene: Node) -> Dictionary:
	var id := chapter_id(scene)
	if id==0: return {}
	var record: Dictionary = {"fields":{},"stage":int(scene.stage),"objective":objective,"objective_done":objective_completed,"supply_checked":supply_checked,"enemies_defeated":enemies_defeated}
	if scene==encounter_chapter:
		for key in ["objective","supply_checked","enemies_defeated"]: record[key] = encounter_snapshot.get(key,record[key])
		record.objective_done = encounter_snapshot.get("objective_completed",false)
	for key in RECORD_FIELDS:
		var value: Variant = scene.get(key)
		if value!=null: record.fields[key] = [value.x,value.y] if value is Vector2 else value
	if scene.stage in [scene.Stage.COMPLETE,scene.Stage.TRANSITION]:
		record.stage = scene.Stage.EXIT if id==1 else scene.Stage.EXPLORE
		if id==5 and night_boss_defeated.get("commander",false): record.fields.mission = 2
	var checkpoint: Variant = scene.get("checkpoint")
	var safe: Vector2 = scene.player.position if scene.player.is_on_floor() else (checkpoint if checkpoint is Vector2 else Vector2(470,570))
	record.player = {"position":[safe.x,safe.y],"health":maxi(1,scene.player.health),"stamina":scene.player.stamina,"facing":scene.player.facing,"ultimate":scene.player.ultimate_charge}
	if is_instance_valid(scene.night_events): record.rumor = scene.night_events.rumor_learned
	chapter_records[str(id)] = record
	return record

func save_campaign(scene: Node = null) -> bool:
	if not campaign_active: return false
	if scene==null: scene = encounter_chapter if is_instance_valid(encounter_chapter) else active_story
	if not is_instance_valid(scene) or scene.player.dead: return false
	if scene!=encounter_chapter and (dialogue_active or scene.stage in [scene.Stage.MENU,scene.Stage.INTRO,scene.Stage.FAILED]): return false
	var id := chapter_id(scene)
	if id==0: return false
	last_chapter = id
	record_chapter(scene)
	var data: Dictionary = {"version":1,"upgrades":upgrade_levels.duplicate(),"points":upgrade_points,"defeat_remainder":upgrade_defeats,"unlocked":unlocked_chapter,"last_chapter":last_chapter,"completed":completed_chapters.duplicate(),"chapters":chapter_records.duplicate(true),"bosses":night_boss_defeated.duplicate(),"endings":unlocked_endings.duplicate(),"notes":story_notes.duplicate(),"heals":heal_stock,"heal_remainder":defeats_toward_heal,"aid_claimed":aid_heal_claimed,"time":time_of_day}
	if scene==encounter_chapter:
		data.heals = encounter_snapshot.get("heal_stock",0)
		data.heal_remainder = encounter_snapshot.get("defeats_toward_heal",0)
		data.aid_claimed = encounter_snapshot.get("aid_heal_claimed",false)
		data.time = encounter_snapshot.get("time_of_day",DAY_START)
	var success := SaveStore.write_slot(save_path,data)
	save_completed.emit(success)
	return success

func request_save() -> void:
	if campaign_active: save_campaign.call_deferred()

func has_save() -> bool:
	return not SaveStore.read_slot(save_path).is_empty()

func load_campaign() -> bool:
	var data := SaveStore.read_slot(save_path)
	if data.is_empty(): return false
	for key in upgrade_levels: upgrade_levels[key] = int(data.upgrades[key])
	upgrade_points = int(data.points)
	upgrade_defeats = clampi(int(data.get("defeat_remainder",0)),0,2)
	unlocked_chapter = int(data.unlocked)
	last_chapter = int(data.last_chapter)
	completed_chapters.clear()
	for id in data.get("completed",[]):
		if int(id) in range(1,6): completed_chapters.append(int(id))
	chapter_records = data.chapters.duplicate(true)
	night_boss_defeated = data.bosses.duplicate()
	unlocked_endings = data.endings.duplicate()
	story_notes = data.get("notes",{}).duplicate()
	heal_stock = clampi(int(data.get("heals",0)),0,9999)
	defeats_toward_heal = clampi(int(data.get("heal_remainder",0)),0,6)
	aid_heal_claimed = bool(data.get("aid_claimed",false))
	time_of_day = fposmod(float(data.get("time",DAY_START)),1)
	campaign_active = true
	stats_changed.emit()
	points_changed.emit()
	return true

func restore_chapter(scene: Node) -> void:
	var id := chapter_id(scene)
	var record: Dictionary = chapter_records.get(str(id),{})
	if not record.is_empty():
		for key in RECORD_FIELDS:
			if record.get("fields",{}).has(key) and scene.get(key)!=null:
				var value: Variant = record.fields[key]
				if key=="checkpoint": value = Vector2(float(value[0]),float(value[1]))
				scene.set(key,value)
		scene.stage = int(record.get("stage",scene.Stage.EXPLORE))
		set_objective(str(record.get("objective","Lanjutkan perjalanan.")),bool(record.get("objective_done",false)))
		supply_checked = int(record.get("supply_checked",0))
		enemies_defeated = int(record.get("enemies_defeated",0))
		if is_instance_valid(scene.night_events): scene.night_events.rumor_learned = bool(record.get("rumor",false))
		dialogue_active = false
		ending_started = false
		scene.dialogue_box.hide()
		scene.choice_container.hide()
		scene.choice_active = false
		scene.lines.clear()
		scene.dialogue_callback = Callable()
		scene.menu.hide()
		scene.hud.show()
		scene.player.controls_enabled = true
		var vitals: Dictionary = pending_vitals if pending_arrival and not pending_vitals.is_empty() else record.get("player",{})
		scene.player.reset_health()
		scene.player.health = clampi(int(vitals.get("health",player_max_health())),1,player_max_health())
		scene.player.stamina = clampf(float(vitals.get("stamina",player_max_stamina())),0,player_max_stamina())
		scene.player.ultimate_charge = clampi(int(vitals.get("ultimate",0)),0,5)
		scene.player.facing = int(vitals.get("facing",1))
		var at: Array = record.get("player",{}).get("position",[470,570])
		scene.player.position = Vector2(float(at[0]),float(at[1]))
		scene.player.health_changed.emit(scene.player.health,scene.player.max_health)
		if id==2 and int(scene.get("mission"))>=4: scene._spawn_patrol()
	if pending_arrival:
		scene.player.position = scene.upgrade_hut.hut.position+Vector2(65,0)
		if record.is_empty() and not pending_vitals.is_empty():
			scene.player.health = clampi(int(pending_vitals.health),1,player_max_health())
			scene.player.stamina = clampf(float(pending_vitals.stamina),0,player_max_stamina())
			scene.player.ultimate_charge = clampi(int(pending_vitals.get("ultimate",0)),0,5)
			scene.player.facing = int(pending_vitals.get("facing",1))
			scene.player.health_changed.emit(scene.player.health,scene.player.max_health)
	scene.cat.position = scene.player.position+Vector2(-70,-56)
	scene.camera.position.x = clampf(scene.player.position.x+150,scene.CAMERA_HALF_WIDTH,scene.player.world_right-scene.CAMERA_HALF_WIDTH)
	pending_restore = 0
	pending_arrival = false
	pending_vitals.clear()
	begin_chapter(scene)

func complete_chapter(id: int, scene: Node) -> void:
	if not completed_chapters.has(id): completed_chapters.append(id)
	unlocked_chapter = maxi(unlocked_chapter,mini(5,id+1))
	begin_chapter(scene)
	save_campaign(scene)

func continue_campaign() -> bool:
	if not load_campaign(): return false
	pending_restore = last_chapter
	start_on_load = true
	get_tree().change_scene_to_file(CHAPTER_PATHS[last_chapter-1])
	return true

func travel_to(id: int, scene: Node, arrival := true) -> void:
	if id<1 or id>unlocked_chapter or _transition_busy: return
	_transition_busy = true
	if chapter_id(scene)==0 and is_instance_valid(encounter_chapter):
		var origin := encounter_chapter
		return_from_encounter(scene)
		scene = origin
	if chapter_id(scene)>0 and scene.stage!=scene.Stage.MENU:
		begin_chapter(scene)
		save_campaign(scene)
		pending_vitals = {"health":scene.player.health,"stamina":scene.player.stamina,"ultimate":scene.player.ultimate_charge,"facing":scene.player.facing}
		scene.player.controls_enabled = false
	elif scene.stage==scene.Stage.MENU or chapter_id(scene)==0:
		pending_vitals = chapter_records.get(str(last_chapter),{}).get("player",{}).duplicate()
	pending_restore = id
	pending_arrival = arrival
	last_chapter = id
	start_on_load = true
	get_tree().paused = false
	ending_started = false
	dialogue_active = false
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var fade := ColorRect.new()
	fade.size = Vector2(1280,720)
	fade.color = Color(0.025,0.04,0.04,0)
	layer.add_child(fade)
	get_tree().root.add_child(layer)
	var out_tween := create_tween()
	out_tween.tween_property(fade,"color:a",1.0,0.18)
	await out_tween.finished
	get_tree().change_scene_to_file(CHAPTER_PATHS[id-1])
	await get_tree().process_frame
	await get_tree().process_frame
	var in_tween := create_tween()
	in_tween.tween_property(fade,"color:a",0.0,0.25)
	await in_tween.finished
	layer.queue_free()
	_transition_busy = false

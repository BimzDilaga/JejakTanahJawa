extends Node
## Device-local audio preferences, independent of new-game progression resets.
signal levels_changed
var levels := {"Master":1.0,"Music":1.0,"SFX":1.0,"Ambience":1.0}
var settings_path := "user://audio-settings.cfg"
var save_timer: Timer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in levels:
		if AudioServer.get_bus_index(key)<0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count-1
			AudioServer.set_bus_name(index,key)
			AudioServer.set_bus_send(index,"Master")
	var config := ConfigFile.new()
	if config.load(settings_path)==OK:
		for key in levels:
			var value: Variant = config.get_value("volume",key,1.0)
			if (value is float or value is int) and is_finite(float(value)): levels[key] = clampf(float(value),0,1)
	_apply()
	save_timer = Timer.new()
	save_timer.wait_time = 0.3
	save_timer.one_shot = true
	add_child(save_timer)
	save_timer.timeout.connect(_save)

func _apply() -> void:
	for key in levels:
		var index := AudioServer.get_bus_index(key)
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(0.0001,float(levels[key]))))
		AudioServer.set_bus_mute(index,float(levels[key])<=0)
	levels_changed.emit()

func set_level(key: String, value: float) -> void:
	if not levels.has(key): return
	levels[key] = clampf(value,0,1)
	_apply()
	save_timer.start()

func _save() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(settings_path).get_base_dir())
	var config := ConfigFile.new()
	for key in levels: config.set_value("volume",key,levels[key])
	config.save(settings_path)

func isolate_test(path: String) -> void:
	save_timer.stop()
	settings_path = path
	for key in levels: levels[key] = 1.0
	_apply()

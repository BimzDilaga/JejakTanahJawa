extends RefCounted
## Checksummed JSON, a temporary file and one previous valid revision.
static func parse(text: String) -> Variant:
	var decoder := JSON.new()
	return decoder.data if decoder.parse(text)==OK else null

static func read_slot(path: String) -> Dictionary:
	for candidate in [path,path+".bak"]:
		if not FileAccess.file_exists(candidate): continue
		var envelope: Variant = parse(FileAccess.get_file_as_string(candidate))
		if not envelope is Dictionary or not envelope.get("payload") is String: continue
		var text: String = envelope.payload
		if text.sha256_text()!=str(envelope.get("sha256","")): continue
		var data: Variant = parse(text)
		if valid(data): return data
	return {}

static func valid(data: Variant) -> bool:
	if not data is Dictionary or int(data.get("version",0))!=1: return false
	if not data.get("upgrades") is Dictionary or not data.get("chapters") is Dictionary: return false
	for key in ["heart","attack","speed","stamina"]:
		var value: Variant = data.upgrades.get(key)
		if not (value is float or value is int) or float(value)!=floorf(float(value)) or int(value)<0 or int(value)>24: return false
	if int(data.upgrades.heart)>3: return false
	if int(data.get("points",-1))<0 or int(data.get("points",0))>100000000: return false
	if int(data.get("unlocked",0))<1 or int(data.get("unlocked",0))>5: return false
	if int(data.get("last_chapter",0))<1 or int(data.get("last_chapter",0))>int(data.unlocked): return false
	if not data.get("bosses") is Dictionary or not data.get("endings") is Dictionary: return false
	for key in data.chapters:
		if str(key) not in ["1","2","3","4","5"] or not data.chapters[key] is Dictionary: return false
	return data.chapters.has(str(int(data.last_chapter)))

static func write_slot(path: String, data: Dictionary) -> bool:
	if not valid(data): return false
	var folder := ProjectSettings.globalize_path(path).get_base_dir()
	if DirAccess.make_dir_recursive_absolute(folder)!=OK: return false
	var text := JSON.stringify(data)
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify({"payload":text,"sha256":text.sha256_text()}))
	file.flush()
	var error := file.get_error()
	file.close()
	if error!=OK: return false
	if FileAccess.file_exists(path):
		# Do not replace a good backup with an externally corrupted primary.
		var primary: Variant = parse(FileAccess.get_file_as_string(path))
		var good := primary is Dictionary and primary.get("payload") is String and str(primary.payload).sha256_text()==str(primary.get("sha256",""))
		if good:
			if FileAccess.file_exists(path+".bak"): DirAccess.remove_absolute(path+".bak")
			if DirAccess.rename_absolute(path,path+".bak")!=OK: return false
		else: DirAccess.remove_absolute(path)
	if DirAccess.rename_absolute(path+".tmp",path)!=OK:
		if FileAccess.file_exists(path+".bak"): DirAccess.copy_absolute(path+".bak",path)
		return false
	return true

static func clear_slot(path: String) -> void:
	for file in [path,path+".bak",path+".tmp"]:
		if FileAccess.file_exists(file): DirAccess.remove_absolute(file)

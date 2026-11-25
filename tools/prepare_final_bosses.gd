extends SceneTree
const OUT := "res://assets/Generated/Bosses/"
const SIZE := Vector2i(448,320)
var manifest: Dictionary

func _initialize() -> void:
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://data/boss_assets.json"))
	_prepare("commander","Commander","res://docs/COMMANDER_ASSET_PROMPTS.json",185)
	_prepare("headless","Headless","res://docs/HEADLESS_ASSET_PROMPTS.json",215)
	var output := FileAccess.open("res://data/boss_assets.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(manifest,"\t"))
	output.close()
	print("FINAL_BOSS_ART_PREPARED")
	quit()

func _prepare(kind: String, folder: String, config_path: String, height: float) -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(config_path))
	for entry in config.prompts:
		var path := OUT+"Sources/"+folder+"/"+str(entry.name)+"-v1.png"
		if not FileAccess.file_exists(path):
			print("WAITING_FOR_ART: ",kind,"/",entry.name)
			return
	manifest[kind] = {}
	for entry in config.prompts:
		_sheet(kind,str(entry.name),OUT+"Sources/"+folder+"/"+str(entry.name)+"-v1.png",int(entry.columns),int(entry.rows),height)
	if kind=="commander":
		for attack in ["rapid","flintshot","finalsalvo"]:
			var files: Array[String] = []
			for index in range(1,11):
				files.append("res://assets/Animasi Karakter/BOSBELANDA/%s/%s-%02d.png" % [attack.to_upper(),"final-salvo" if attack=="finalsalvo" else "frame",index])
			_individual(kind,attack,files,height)
		var chains := [["light","combo_1_2","flintshot","combo_1_4","heavy"],["combo_2_1","flintshot","rapid","heavy"],["flintshot","combo_3_2","rapid","finalsalvo","combo_3_5"]]
		for chain in range(3):
			for strike in range(chains[chain].size()):
				var name := "combo_%d_%d" % [chain+1,strike+1]
				if name!=str(chains[chain][strike]): _alias(kind,name,str(chains[chain][strike]))
	else:
		var chains := [["light","backhand","light","backhand","heavy"],["lunge","light","low_spin","heavy"],["vanish","leap_slam","light","low_spin","ultimate"]]
		for chain in range(3):
			for strike in range(chains[chain].size()):
				_alias(kind,"combo_%d_%d" % [chain+1,strike+1],str(chains[chain][strike]))

func _sheet(kind: String, animation: String, path: String, columns: int, rows: int, height: float) -> void:
	var sheet := Image.new()
	assert(sheet.load(ProjectSettings.globalize_path(path))==OK,path)
	sheet.convert(Image.FORMAT_RGBA8)
	var frames: Array[Image] = []
	for index in range(columns*rows):
		var col := index%columns
		var row := index/columns
		var x0 := roundi(float(col)*sheet.get_width()/columns)
		var x1 := roundi(float(col+1)*sheet.get_width()/columns)
		var y0 := roundi(float(row)*sheet.get_height()/rows)
		var y1 := roundi(float(row+1)*sheet.get_height()/rows)
		frames.append(sheet.get_region(Rect2i(x0,y0,x1-x0,y1-y0)))
	# The generated last cell returned to standing; keep the last kneeling pose for the hold.
	if kind=="headless" and animation=="stagger": frames[5] = frames[4].duplicate()
	_save(kind,animation,frames,height,path,false)

func _individual(kind: String, animation: String, paths: Array[String], height: float) -> void:
	var frames: Array[Image] = []
	for path in paths:
		var image := Image.new()
		assert(image.load(ProjectSettings.globalize_path(path))==OK,path)
		frames.append(image)
	_save(kind,animation,frames,height,paths[0].get_base_dir(),true)

func _save(kind: String, animation: String, frames: Array[Image], height: float, source: String, flip: bool) -> void:
	for image in frames:
		image.convert(Image.FORMAT_RGBA8)
		var corner := image.get_pixel(0,0)
		if corner.a>0.5 and minf(corner.r,minf(corner.g,corner.b))>0.75: _clear_connected_white(image)
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var pixel := image.get_pixel(x,y)
				image.set_pixel(x,y,Color(pixel.r,pixel.g,pixel.b,1) if pixel.a>=0.5 else Color.TRANSPARENT)
	var reference := frames[frames.size()-1] if animation=="spawn" else frames[0]
	var factor := height/maxf(1,reference.get_used_rect().size.y)
	var paths: Array[String] = []
	for index in range(frames.size()):
		var image := frames[index]
		var feet := image.get_used_rect().end.y
		image.resize(maxi(1,roundi(image.get_width()*factor)),maxi(1,roundi(image.get_height()*factor)),Image.INTERPOLATE_NEAREST)
		var canvas := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
		canvas.fill(Color.TRANSPARENT)
		canvas.blit_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),Vector2i(roundi((SIZE.x-image.get_width())/2.0),roundi(304-feet*factor)))
		if flip: canvas.flip_x()
		var path := OUT+"%s_%s_%02d.png" % [kind,animation,index+1]
		assert(canvas.save_png(path)==OK,path)
		paths.append(path)
	manifest[kind][animation] = {"files":paths,"source":source,"placeholder":false}

func _alias(kind: String, name: String, source: String) -> void:
	manifest[kind][name] = manifest[kind][source].duplicate(true)
	manifest[kind][name]["shared_animation"] = source

func _clear_connected_white(image: Image) -> void:
	# Preserve white trousers enclosed by dark outlines; remove only border-connected matte.
	var width := image.get_width()
	var height := image.get_height()
	var seen := PackedByteArray()
	seen.resize(width*height)
	var pending := PackedInt32Array()
	for x in range(width):
		pending.append(x)
		pending.append((height-1)*width+x)
	for y in range(height):
		pending.append(y*width)
		pending.append(y*width+width-1)
	var cursor := 0
	while cursor<pending.size():
		var index := pending[cursor]
		cursor += 1
		if seen[index]!=0: continue
		seen[index] = 1
		var x := index%width
		var y := index/width
		var pixel := image.get_pixel(x,y)
		var minimum := minf(pixel.r,minf(pixel.g,pixel.b))
		var maximum := maxf(pixel.r,maxf(pixel.g,pixel.b))
		if pixel.a>=0.5 and not (minimum>0.60 and maximum-minimum<0.12): continue
		image.set_pixel(x,y,Color.TRANSPARENT)
		if x>0: pending.append(index-1)
		if x<width-1: pending.append(index+1)
		if y>0: pending.append(index-width)
		if y<height-1: pending.append(index+width)

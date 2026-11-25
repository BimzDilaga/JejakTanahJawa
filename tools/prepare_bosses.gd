extends SceneTree
## Reproducible import of supplied sheets; original files remain untouched.
const ROOT := "res://assets/Animasi Karakter/Boss Urban Legend/"
const OUT := "res://assets/Generated/Bosses/"
const SIZE := Vector2i(448,320)
const FEET := 304
var manifest: Dictionary = {"buto":{},"banaspati":{}}

func _initialize() -> void:
	if FileAccess.file_exists("res://data/boss_assets.json"):
		var existing: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/boss_assets.json"))
		for kind in ["commander","headless"]:
			if existing.has(kind): manifest[kind] = existing[kind]
	DirAccess.make_dir_recursive_absolute(OUT)
	_sheet("buto","walk","Buto Ijo/Waking/Buto Ijo Boss Walk Cycle.png",4,2,0.56,true,true)
	_sheet("buto","light","Buto Ijo/Light Attack/Buto Ijo Light Attack Sprite Sheet.png",3,2,0.53)
	_sheet("buto","heavy","Buto Ijo/Heavy Attack/Buto Ijo Heavy Attack Sprite Sheet.png",3,2,0.53)
	for chain in range(1,4):
		var folder := "Chained attack 1" if chain==1 else "Chained Attack %d" % chain
		for strike in range(1,5 if chain==2 else 6):
			_sheet("buto","combo_%d_%d" % [chain,strike],"Buto Ijo/Chained attack/%s/CA KE %d.png" % [folder,strike],3,2,0.53)
	_sheet("buto","wave","Buto Ijo/Projectile/Pixel Earth Shockwave Sprite Sheet.png",4,2,0.34)
	_alias("buto","idle","light",1)
	_alias("buto","spawn","idle",1,true)
	_alias("buto","death","combo_3_5",1,true,6)
	_make_buto_stagger()
	_sheet("banaspati","walk","Banaspati/Walking/Banaspati Flaming Sword Walk Cycle.png",8,1,0.60)
	_sheet("banaspati","flight","Banaspati/Flying banaspati/ChatGPT Image Nov 23, 2026, 01_57_10 PM-1.png",6,1,0.40,true)
	var flight_files := ["01_57_12 PM-2","01_57_14 PM-3","01_57_15 PM-4","01_57_16 PM-5","01_57_17 PM-6","01_57_18 PM-7"]
	var flight_names := ["rise","hover","descend","hurt","air_stagger","air_death"]
	for index in range(flight_files.size()):
		_sheet("banaspati",flight_names[index],"Banaspati/Flying banaspati/ChatGPT Image Nov 23, 2026, %s.png" % flight_files[index],6,1,0.40,true)
	_sheet("banaspati","stagger","Banaspati/Stance/Banaspati Stance Break Animation (1).png",6,1,0.37,false,false,600)
	_sheet("banaspati","spawn","Banaspati/Stance/Banaspati Flame Spawn Animation Sprite Sheet.png",8,1,0.50,false,false,570,[0,190,380,610,900,1190,1490,1840,2172])
	_sheet("banaspati","death",_find("Banaspati/Stance","*Death.png"),8,1,0.43,false,false,590)
	var ground := ["Fiery Claw Swipe Sprite Sheet (1).png","Flaming Claw Swipe Animation Sprite Sheet (1).png","ChatGPT Image Nov 23, 2026, 01_58_42 PM.png","ChatGPT Image Nov 23, 2026, 01_59_32 PM.png","ChatGPT Image Nov 23, 2026, 02_00_49 PM.png"]
	for index in range(ground.size()):
		_sheet("banaspati","combo_1_%d" % [index+1],"Banaspati/Chained attack/Chained Attack 1/"+ground[index],6,1,0.40,true)
	var air := ["Fiery Banaspati Fireball Casting Sprite Sheet-1.png","Banaspati Flame Casting Sprite Sheet-2.png","Banaspati Flaming Cast Sprite Strip-3.png","Banaspati Flaming Sword Casting Sprite Sheet-4.png","Banaspati Flame Sword Sprite Sheet-5.png",_find_name("Banaspati/Chained attack/Chained Attack 2","*Animation-6.png"),"Banaspati Firecaster Animation Sprite Sheet-7.png","Banaspati Fire Demon Attack Sprite Sheet-8.png"]
	for index in range(air.size()):
		_sheet("banaspati","air_%d" % [index+1],"Banaspati/Chained attack/Chained Attack 2/"+air[index],6,1,0.40,true)
	var ultimate := ["Banaspati Flame Marking Animation-1.png","Banaspati Flame Warrior Casting Sprite Sheet-2.png","Six-Frame Fire Warrior Summoning Animation-3.png","Banaspati Fire Boss Attack Spritesheet-4.png","Banaspati Flame Warrior Attack Sequence-5.png"]
	for index in range(ultimate.size()):
		_sheet("banaspati","combo_3_%d" % [index+1],"Banaspati/Chained attack/Chained Attack 3/"+ultimate[index],6,1,0.40,true)
	var fx := ["02_06_57 PM-1","02_06_58 PM-2","02_06_59 PM-3","02_07_01 PM-4","02_07_02 PM-5","02_07_03 PM-6","02_07_06 PM-7","02_07_09 PM-8"]
	for index in range(fx.size()):
		_sheet("banaspati","fx_%d" % [index+1],"Banaspati/Projectile dan mark projectile/ChatGPT Image Nov 23, 2026, %s.png" % fx[index],6,1,0.25)
	_sheet("banaspati","platform","Banaspati/Platform fall/Progressive Damage Platform Tiles.png",4,1,0.45)
	_alias("banaspati","idle","walk",1)
	_alias("banaspati","light","combo_1_1",6,true)
	_alias("banaspati","heavy","combo_1_5",6,true)
	_alias("banaspati","run","walk",8,true)
	preload("res://tools/combat_art.gd").prepare_buto(manifest)
	var file := FileAccess.open("res://data/boss_assets.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"))
	file.close()
	print("BOSS_ASSETS_PREPARED: ",manifest.buto.size()," Buto animations, ",manifest.banaspati.size()," Banaspati animations")
	quit()

func _find(folder: String, pattern: String) -> String:
	return folder.path_join(_find_name(folder,pattern))

func _find_name(folder: String, pattern: String) -> String:
	for file in DirAccess.get_files_at(ROOT+folder):
		if file.matchn(pattern):
			return file
	assert(false,"Missing boss sheet: "+folder+"/"+pattern)
	return ""

func _sheet(kind: String, animation: String, file: String, columns: int, rows: int, factor: float, flip := false, black := false, baseline := -1, edges: Array = []) -> void:
	var source := Image.new()
	assert(source.load(ProjectSettings.globalize_path(ROOT+file))==OK, file)
	source.convert(Image.FORMAT_RGBA8)
	if source.get_pixel(0,0).r>0.9 and source.get_pixel(0,0).a>0.12:
		_clear_white_background(source)
	_clean(source,black)
	var paths: Array[String] = []
	for index in range(columns*rows):
		var col := index%columns
		var row := index/columns
		var x0 := roundi(float(col)*source.get_width()/columns) if edges.is_empty() else int(edges[col])
		var x1 := roundi(float(col+1)*source.get_width()/columns) if edges.is_empty() else int(edges[col+1])
		var y0 := roundi(float(row)*source.get_height()/rows)
		var y1 := roundi(float(row+1)*source.get_height()/rows)
		var image := source.get_region(Rect2i(x0,y0,x1-x0,y1-y0))
		if kind=="buto" and animation=="walk":
			for y in range(411,image.get_height()):
				for x in range(image.get_width()): image.set_pixel(x,y,Color.TRANSPARENT)
		var used := image.get_used_rect()
		var feet := used.end.y if baseline<0 else baseline
		image.resize(maxi(1,roundi(image.get_width()*factor)),maxi(1,roundi(image.get_height()*factor)),Image.INTERPOLATE_NEAREST)
		var canvas := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
		canvas.fill(Color.TRANSPARENT)
		canvas.blit_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),Vector2i(roundi(SIZE.x/2.0-image.get_width()/2.0),roundi(FEET-feet*factor)))
		if flip:
			canvas.flip_x()
		var path := OUT+"%s_%s_%02d.png" % [kind,animation,index+1]
		assert(canvas.save_png(path)==OK)
		paths.append(path)
	manifest[kind][animation] = {"files":paths,"source":ROOT+file,"placeholder":false}

func _clean(image: Image, black: bool) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x,y)
			if black:
				pixel.a *= smoothstep(0.02,0.14,maxf(pixel.r,maxf(pixel.g,pixel.b)))
			if pixel.a<0.12:
				pixel = Color.TRANSPARENT
			image.set_pixel(x,y,pixel)

func _alias(kind: String, name: String, original: String, count: int, placeholder := false, first := 1) -> void:
	var paths: Array = manifest[kind][original].files.slice(first-1,first-1+count)
	manifest[kind][name] = {"files":paths,"source":manifest[kind][original].source,"placeholder":placeholder}

func _make_buto_stagger() -> void:
	var idle := Image.new()
	assert(idle.load(ProjectSettings.globalize_path(manifest.buto.idle.files[0]))==OK)
	var kneel := Image.new()
	assert(kneel.load(ProjectSettings.globalize_path(manifest.buto.combo_3_5.files[5]))==OK)
	var paths: Array[String] = []
	for index in range(6):
		var canvas := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
		canvas.fill(Color.TRANSPARENT)
		var factor := lerpf(1.0,0.84,index/5.0)
		var pose := idle.duplicate() as Image
		pose.resize(SIZE.x,roundi(SIZE.y*factor),Image.INTERPOLATE_NEAREST)
		canvas.blit_rect(pose,Rect2i(Vector2i.ZERO,pose.get_size()),Vector2i(0,roundi(FEET*(1.0-factor))))
		if index==5:
			canvas = kneel.duplicate() as Image
		var path := OUT+"buto_stagger_%02d.png" % [index+1]
		assert(canvas.save_png(path)==OK)
		paths.append(path)
	manifest.buto.stagger = {"files":paths,"source":"Light pose → kneeling pose from combo 3 finisher","placeholder":true}

func _clear_white_background(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var seen := PackedByteArray()
	seen.resize(width*height)
	var queue := PackedInt32Array()
	for x in range(width):
		queue.append(x)
		queue.append((height-1)*width+x)
	for y in range(height):
		queue.append(y*width)
		queue.append(y*width+width-1)
	var cursor := 0
	while cursor<queue.size():
		var index := queue[cursor]
		cursor += 1
		if seen[index]!=0:
			continue
		seen[index] = 1
		var x := index%width
		var y := index/width
		var pixel := image.get_pixel(x,y)
		var low := minf(pixel.r,minf(pixel.g,pixel.b))
		if low<0.88 or maxf(pixel.r,maxf(pixel.g,pixel.b))-low>0.08:
			continue
		image.set_pixel(x,y,Color.TRANSPARENT)
		if x>0: queue.append(index-1)
		if x<width-1: queue.append(index+1)
		if y>0: queue.append(index-width)
		if y<height-1: queue.append(index+width)

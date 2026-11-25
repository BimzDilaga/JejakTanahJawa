extends RefCounted
## Normalize generated sheets without changing their source images.
const JAKA := "res://assets/Generated/Jaka/"
const BOSSES := "res://assets/Generated/Bosses/"

static func prepare_jaka() -> void:
	_slice(JAKA+"Concepts/chained-combo-sheet-v1.png",6,3,JAKA+"chain",Vector2i(224,144),144,112.0/270.0,[],false,true)
	_slice(JAKA+"Concepts/jump-sheet-v1.png",3,2,JAKA+"jump",Vector2i(224,144),144,112.0/426.0)
	_slice(JAKA+"Concepts/reactions-sheet-v1.png",6,2,JAKA+"reaction",Vector2i(224,144),144,112.0/337.0,[],false,true)
	for action: String in ["dash","backdash"]:
		var file := JAKA+"Concepts/"+action+"-sheet-v1.png"
		if FileAccess.file_exists(file):
			_slice(file,3,2,JAKA+action,Vector2i(224,144),144,112.0/(436.0 if action=="dash" else 468.0))

static func prepare_buto(manifest: Dictionary) -> void:
	for action: String in ["spawn","stagger","death"]:
		var source := BOSSES+"Sources/buto-"+action+"-v1.png"
		var factor := 224.0/(451.0 if action=="spawn" else 460.0)
		var paths := _slice(source,3,2,BOSSES+"buto_"+action,Vector2i(448,320),304,factor,[],action=="stagger")
		manifest.buto[action] = {"files":paths,"source":source,"placeholder":false}

static func _slice(source_path: String, columns: int, rows: int, prefix: String, size: Vector2i, feet: int, factor: float, baselines: Array = [], flip := false, row_names := false) -> Array[String]:
	var sheet := Image.new()
	assert(sheet.load(ProjectSettings.globalize_path(source_path))==OK,source_path)
	sheet.convert(Image.FORMAT_RGBA8)
	var paths: Array[String] = []
	for index in range(columns*rows):
		var col := index%columns
		var row := index/columns
		var x0 := roundi(float(col)*sheet.get_width()/columns)
		var x1 := roundi(float(col+1)*sheet.get_width()/columns)
		var y0 := roundi(float(row)*sheet.get_height()/rows)
		var y1 := roundi(float(row+1)*sheet.get_height()/rows)
		var frame := sheet.get_region(Rect2i(x0,y0,x1-x0,y1-y0))
		# Hard alpha edges keep low-alpha background RGB out of the pixel sprites.
		for y in range(frame.get_height()):
			for x in range(frame.get_width()):
				var color := frame.get_pixel(x,y)
				frame.set_pixel(x,y,Color(color.r,color.g,color.b,1) if color.a>=0.5 else Color.TRANSPARENT)
		var used := frame.get_used_rect()
		var baseline := float(used.end.y) if baselines.is_empty() else float(baselines[index])
		frame.resize(maxi(1,roundi(frame.get_width()*factor)),maxi(1,roundi(frame.get_height()*factor)),Image.INTERPOLATE_NEAREST)
		var canvas := Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
		canvas.fill(Color.TRANSPARENT)
		canvas.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),Vector2i(roundi((size.x-frame.get_width())/2.0),roundi(feet-baseline*factor)))
		if flip: canvas.flip_x()
		var path := prefix+("_%d_%02d.png" % [row+1,col+1] if row_names else "_%02d.png" % [index+1])
		assert(canvas.save_png(path)==OK,path)
		paths.append(path)
	return paths

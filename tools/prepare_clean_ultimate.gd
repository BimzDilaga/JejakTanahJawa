extends SceneTree
## Cut the transparent replacement without modifying the supplied RGB original.
func _initialize() -> void:
	prepare()
	quit()

static func prepare() -> void:
	var source := Image.new()
	assert(source.load(ProjectSettings.globalize_path("res://assets/Generated/Jaka/Concepts/ultimate-clean-v1.png"))==OK)
	source.convert(Image.FORMAT_RGBA8)
	var frames: Array[Image] = []
	for index in range(8):
		var col := index%4
		var row := index/4
		var left := roundi(float(col)*source.get_width()/4)
		var right := roundi(float(col+1)*source.get_width()/4)
		var top := roundi(float(row)*source.get_height()/2)
		var bottom := roundi(float(row+1)*source.get_height()/2)
		var frame := source.get_region(Rect2i(left,top,right-left,bottom-top))
		for y in range(frame.get_height()):
			for x in range(frame.get_width()):
				var color := frame.get_pixel(x,y)
				frame.set_pixel(x,y,Color(color.r,color.g,color.b,1) if color.a>=0.5 else Color.TRANSPARENT)
		frames.append(frame)
	var factor := 112.0/frames[0].get_used_rect().size.y
	for index in range(8):
		var frame := frames[index]
		var feet := frame.get_used_rect().end.y
		frame.resize(roundi(frame.get_width()*factor),roundi(frame.get_height()*factor),Image.INTERPOLATE_NEAREST)
		var target := Image.create(224,144,false,Image.FORMAT_RGBA8)
		target.fill(Color.TRANSPARENT)
		target.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),Vector2i(roundi((224-frame.get_width())/2.0),roundi(144-feet*factor)))
		assert(target.save_png("res://assets/Generated/Jaka/ultimate_clean_%02d.png" % [index+1])==OK)
	print("CLEAN_ULTIMATE_PREPARED: eight frames with binary alpha, source preserved")

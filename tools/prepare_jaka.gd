extends SceneTree
## Deterministic sprite import. Source art is never overwritten.
const ROOT := "res://assets/Animasi Karakter/Jaka New/"
const OUTPUT := "res://assets/Generated/Jaka/"
const CANVAS := Vector2i(224, 144)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	if "--attack-only" in OS.get_cmdline_user_args():
		_attack()
		print("JAKA_ATTACK_PREPARED: 6 dedicated keris slash frames")
		quit()
		return
	_idle()
	if "--idle-only" in OS.get_cmdline_user_args():
		print("JAKA_IDLE_PREPARED: original Javanese-Inspired Pixel Art Warrior.png")
		quit()
		return
	_attack()
	_locomotion("walk", "Walking/Jaka’s Eight-Frame Walking Cycle.png", [Rect2i(6,38,296,641), Rect2i(320,43,182,637), Rect2i(589,43,188,638), Rect2i(844,43,214,638), Rect2i(1087,51,271,631), Rect2i(1395,50,200,632), Rect2i(1686,51,176,631), Rect2i(1895,51,262,631)], 680, 112.0 / 640.0)
	_locomotion("run", "Running/Batik Runner Pixel Art Sprite Sheet.png", [Rect2i(23,133,241,485), Rect2i(246,133,305,484), Rect2i(525,141,320,472), Rect2i(792,133,330,451), Rect2i(1111,139,261,479), Rect2i(1403,139,230,479), Rect2i(1666,145,238,473), Rect2i(1935,139,231,479)], 616, 112.0 / 560.0)
	_strip("heal", "Healing/Eight-Frame Green Healing Animation Sprite Sheet (1).png", 8, 1, 671.0, 112.0 / 584.0, [140,410,680,950,1230,1500,1780,2050])
	_strip("hurt", "Kena Hit/Javanese Warrior Impact Sprite Sheet.png", 3, 1, 702.0, 112.0 / 659.0, [400,1050,1680])
	_strip("parry", "Parry/Indonesian Keris Parry Sprite Sheet.png", 3, 2, 483.0, 112.0 / 462.0, [250,762,1274,250,762,1274])
	_strip("ultimate", "Ultimate/Golden Keris Ultimate Sprite Sequence.png", 4, 2, 348.0, 112.0 / 324.0, [264,807,1350,1893,264,807,1350,1893], true)
	_strip("ultimate_wave", "Projectile Ultimate/Ornate Golden Energy Wave Sprite Sheet.png", 4, 2, 330.0, 0.27, [271,814,1357,1900,271,814,1357,1900])
	assert(_read("Walking/Jaka’s Eight-Frame Walking Cycle.png").get_region(Rect2i(40,35,210,335)).save_png(OUTPUT + "portrait.png") == OK)
	preload("res://tools/combat_art.gd").prepare_jaka()
	if FileAccess.file_exists("res://assets/Generated/Jaka/Concepts/ultimate-clean-v1.png"):
		preload("res://tools/prepare_clean_ultimate.gd").prepare()
	print("JAKA_PREPARED: idle, attack, combo, jump, reactions, walk, run, heal, parry, ultimate")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--preview="):
			_preview(argument.trim_prefix("--preview="))
	quit()

func _preview(path: String) -> void:
	var atlas := Image.create(CANVAS.x * 8, CANVAS.y * 7, false, Image.FORMAT_RGBA8)
	atlas.fill(Color("66776b"))
	var rows := ["walk", "run", "parry", "heal", "hurt", "ultimate", "ultimate_wave"]
	var counts := [8, 8, 6, 8, 3, 8, 8]
	for row in range(rows.size()):
		for frame in range(counts[row]):
			var image := Image.new()
			assert(image.load(ProjectSettings.globalize_path(OUTPUT + "%s_%02d.png" % [rows[row], frame + 1])) == OK)
			atlas.blend_rect(image, Rect2i(Vector2i.ZERO, CANVAS), Vector2i(frame * CANVAS.x, row * CANVAS.y))
	assert(atlas.save_png(path) == OK)

func _read(file: String) -> Image:
	var source := Image.new()
	assert(source.load(ProjectSettings.globalize_path(ROOT + file)) == OK, "Missing Jaka source: " + file)
	source.convert(Image.FORMAT_RGBA8)
	return source

func _idle() -> void:
	# The supplied image already has alpha. Ignore faint pixels outside its silhouette.
	var frame := _read("Javanese-Inspired Pixel Art Warrior.png").get_region(Rect2i(272,82,462,1360))
	_keep_body(frame)
	_save("idle",0,frame,231.0,1360.0,112.0/1360.0)

func _attack() -> void:
	var source := _read("Attack/Jaka’s Keris Slash Animation.png")
	# The fourth slash crosses the nominal grid edge; preserve it without the next pose.
	var regions := [Rect2i(165,20,235,460),Rect2i(558,40,345,440),Rect2i(1035,38,465,445),Rect2i(85,534,460,448),Rect2i(580,548,355,435),Rect2i(1155,528,220,458)]
	var anchors := [278.0,737.0,1185.0,273.0,729.0,1264.0]
	for index in range(regions.size()):
		var rect: Rect2i = regions[index]
		var frame := source.get_region(rect)
		for y in range(frame.get_height()):
			for x in range(frame.get_width()):
				if frame.get_pixel(x,y).a<0.08: frame.set_pixel(x,y,Color.TRANSPARENT)
		_save("attack",index,frame,anchors[index]-rect.position.x,(474.0 if index<3 else 978.0)-rect.position.y,112.0/441.0)

func _locomotion(animation: String, file: String, regions: Array, baseline: int, factor: float) -> void:
	var sheet := _read(file)
	for index in range(regions.size()):
		var rect: Rect2i = regions[index]
		var frame := sheet.get_region(rect)
		_keep_body(frame)
		# Anchor on the torso rather than the moving hands or stretched feet.
		var xs: Array[int] = []
		var band_y := roundi(frame.get_height() * 0.38)
		for y in range(band_y, mini(band_y + 24, frame.get_height())):
			for x in range(frame.get_width()):
				if frame.get_pixel(x, y).a > 0.5:
					xs.append(x)
		xs.sort()
		var anchor := float(xs[xs.size() / 2]) if not xs.is_empty() else frame.get_width() / 2.0
		_save(animation, index, frame, anchor, baseline - rect.position.y, factor)

func _strip(animation: String, file: String, columns: int, rows: int, baseline: float, factor: float, anchors: Array, black_matte := false) -> void:
	var sheet := _read(file)
	for index in range(columns * rows):
		var col := index % columns
		var row := index / columns
		var left := roundi(float(col) * sheet.get_width() / columns)
		var right := roundi(float(col + 1) * sheet.get_width() / columns)
		var top := roundi(float(row) * sheet.get_height() / rows)
		var bottom := roundi(float(row + 1) * sheet.get_height() / rows)
		var frame := sheet.get_region(Rect2i(left, top, right - left, bottom - top))
		if black_matte:
			_clear_black_matte(frame)
		for y in range(frame.get_height()):
			for x in range(frame.get_width()):
				if frame.get_pixel(x, y).a < 0.025:
					frame.set_pixel(x, y, Color.TRANSPARENT)
		var feet := baseline
		if animation == "parry" and row == 1:
			feet = 484.0
		_save(animation, index, frame, float(anchors[index]) - left, feet, factor)

func _save(animation: String, index: int, frame: Image, anchor: float, baseline: float, factor: float) -> void:
	frame.resize(maxi(1, roundi(frame.get_width() * factor)), maxi(1, roundi(frame.get_height() * factor)), Image.INTERPOLATE_NEAREST)
	var canvas := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	var at := Vector2i(roundi(CANVAS.x / 2.0 - anchor * factor), roundi(CANVAS.y - baseline * factor))
	canvas.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), at)
	assert(canvas.save_png(OUTPUT + "%s_%02d.png" % [animation, index + 1]) == OK)

func _keep_body(image: Image) -> void:
	# Running poses overlap in X; retain the main connected silhouette only.
	var width := image.get_width()
	var height := image.get_height()
	var seen := PackedByteArray()
	seen.resize(width * height)
	var largest := PackedInt32Array()
	for y in range(height):
		for x in range(width):
			var start := y * width + x
			if seen[start] != 0 or image.get_pixel(x, y).a <= 0.5:
				continue
			var component := PackedInt32Array([start])
			seen[start] = 1
			var cursor := 0
			while cursor < component.size():
				var current := component[cursor]
				cursor += 1
				var cx := current % width
				var cy := current / width
				for offset: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					var next := Vector2i(cx, cy) + offset
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var ni := next.y * width + next.x
					if seen[ni] == 0 and image.get_pixelv(next).a > 0.5:
						seen[ni] = 1
						component.append(ni)
			if component.size() > largest.size():
				largest = component
	var keep := PackedByteArray()
	keep.resize(width * height)
	for pixel in largest:
		keep[pixel] = 1
	for y in range(height):
		for x in range(width):
			if keep[y * width + x] == 0:
				image.set_pixel(x, y, Color.TRANSPARENT)

func _clear_black_matte(image: Image) -> void:
	# This source is RGB. Fade near-black matte even inside closed energy rings;
	# keep normal clothing tones opaque and preserve the original RGB artwork.
	var width := image.get_width()
	var height := image.get_height()
	for y in range(height):
		for x in range(width):
			var pixel := image.get_pixel(x, y)
			var brightness := maxf(pixel.r, maxf(pixel.g, pixel.b))
			pixel.a *= smoothstep(0.02, 0.16, brightness)
			image.set_pixel(x, y, pixel if pixel.a >= 0.01 else Color.TRANSPARENT)

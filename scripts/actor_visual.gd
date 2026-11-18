extends RefCounted

# Measured source regions, preserving the original PNG files.
const REGIONS: Dictionary = {
	"Jaka.png": Rect2(270, 83, 510, 1370),
	"Tentara Belanda.png": Rect2(140, 18, 878, 1484),
	"NPC Ibu2.png": Rect2(254, 152, 463, 1314),
	"NPC cwo.png": Rect2(253, 150, 483, 1330),
	"sesepuh.png": Rect2(264, 102, 499, 1377),
	"Cuking Taby.png": Rect2(279, 118, 999, 822),
	"Pangeran Diponegoro.png": Rect2(265, 33, 517, 1468),
}

static func make_sprite(path: String, height: float, region: Rect2 = Rect2()) -> Sprite2D:
	var sprite := Sprite2D.new()
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		return sprite
	if region.size == Vector2.ZERO:
		region = REGIONS.get(path.get_file(), Rect2(Vector2.ZERO, texture.get_size()))
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	sprite.texture = atlas
	var factor: float = height / region.size.y
	sprite.scale = Vector2(factor, factor)
	sprite.position.y = -height / 2.0
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return sprite

static func _normalized(texture: Texture2D, region: Rect2, height: float = 112.0, key_white: bool = false, canvas_width: int = 90, white_threshold: float = 0.91, trim_islands: bool = false) -> Texture2D:
	# Normalize all animation frames to a common canvas and feet anchor.
	var source: Image = texture.get_image().get_region(Rect2i(region))
	if key_white:
		# Remove pale neutral backgrounds from supplied animation frames.
		source.convert(Image.FORMAT_RGBA8)
		for y in range(source.get_height()):
			for x in range(source.get_width()):
				var pixel := source.get_pixel(x, y)
				var lightness := minf(pixel.r, minf(pixel.g, pixel.b))
				if lightness > white_threshold and maxf(pixel.r, maxf(pixel.g, pixel.b)) - lightness < 0.09:
					pixel.a = 0.0
					source.set_pixel(x, y, pixel)
	if trim_islands:
		_keep_character_island(source)
	var factor: float = height / float(source.get_height())
	source.resize(maxi(1, roundi(source.get_width() * factor)), roundi(height), Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(canvas_width, 112, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	canvas.blit_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), Vector2i((canvas_width-source.get_width()) / 2, 112-source.get_height()))
	return ImageTexture.create_from_image(canvas)

static var _soldier_frames: SpriteFrames
static var _jaka_frames: SpriteFrames

static func soldier_frames() -> SpriteFrames:
	if _soldier_frames != null:
		return _soldier_frames
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_soldier_strip(frames, "walk", "Tentara_Jalan.png", [0, 222, 444, 668, 900, 1123, 1347, 1567, 1780, 1984, 2172], 142, 500, 12.0, true)
	_add_soldier_strip(frames, "shoot", "Tentara_Menembak.png", [0, 204, 440, 657, 888, 1150, 1394, 1581, 1789, 1989, 2172], 190, 400, 30.0, false)
	_add_soldier_strip(frames, "defeat", "Tentara_Mati.png", [0, 202, 421, 648, 871, 1075, 1284, 1534, 1845, 2172], 190, 400, 12.0, false)
	_soldier_frames = frames
	return frames

static func _add_soldier_strip(frames: SpriteFrames, animation: String, file: String, edges: Array[int], top: int, height: int, fps: float, loop: bool) -> void:
	var sheet: Texture2D = load("res://assets/Animasi Karakter/Tentara/" + file)
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loop)
	for index in range(edges.size() - 1):
		var region := Rect2(edges[index], top, edges[index + 1] - edges[index], height)
		frames.add_frame(animation, _normalized(sheet, region, 112.0, false, 104))

static func jaka_frames() -> SpriteFrames:
	if _jaka_frames != null:
		return _jaka_frames
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 1.0)
	var idle: Texture2D = load("res://assets/Karakter/Jaka.png") as Texture2D
	frames.add_frame("idle", _normalized(idle, REGIONS["Jaka.png"]))
	_add_jaka_folder(frames, "run", "lari", 12.0, 138, 453, 104, 0.84)
	frames.set_animation_loop("run", true)
	_add_jaka_folder(frames, "walk", "jalan_10framer", 10.0, 143, 462, 104, 0.84)
	frames.set_animation_loop("walk", true)
	_add_jaka_folder(frames, "jump", "lompat", 14.0, 104, 491, 104, 0.84)
	_add_jaka_folder(frames, "hurt", "tertembak", 40.0, 206, 356, 104, 0.84)
	_add_jaka_folder(frames, "parry", "parry_10_frames", 25.0, 0, 0, 104, 1.0)
	_add_jaka_folder(frames, "heal", "heal", 14.0, 190, 380, 90, 0.84)
	_add_jaka_folder(frames, "ultimate", "ulti", 20.0, 30, 294, 160, 0.84)
	frames.add_animation("bamboo_attack")
	frames.set_animation_speed("bamboo_attack", 9.0)
	frames.set_animation_loop("bamboo_attack", false)
	for index in range(mini(3, frames.get_frame_count("ultimate"))):
		frames.add_frame("bamboo_attack", frames.get_frame_texture("ultimate", index))
	_jaka_frames = frames
	return frames

# Explicit lists preserve frame order in the editor and exported packages.
const JAKA_FRAME_FILES := {
  "lari": [
    "IMG_20261110_093313.png",
    "IMG_20261110_093354.png",
    "IMG_20261110_093430.png",
    "IMG_20261110_093539.png",
    "IMG_20261110_093616.png",
    "IMG_20261110_093649.png",
    "IMG_20261110_093738.png",
    "IMG_20261110_093801.png",
    "IMG_20261110_093822.png",
    "IMG_20261110_093916.png"
  ],
  "jalan_10framer": [
    "IMG_20261110_091638.png",
    "IMG_20261110_091652.png",
    "IMG_20261110_091846.png",
    "IMG_20261110_091906.png",
    "IMG_20261110_091924.png",
    "IMG_20261110_091958.png",
    "IMG_20261110_092015.png",
    "IMG_20261110_092030.png",
    "IMG_20261110_092056.png",
    "IMG_20261110_092108.png"
  ],
  "lompat": [
    "IMG_20261110_094036.png",
    "IMG_20261110_094048.png",
    "IMG_20261110_094101.png",
    "IMG_20261110_094115.png",
    "IMG_20261110_094131.png",
    "IMG_20261110_094156.png",
    "IMG_20261110_094215.png",
    "IMG_20261110_094240.png",
    "IMG_20261110_094257.png",
    "IMG_20261110_094310.png"
  ],
  "tertembak": [
    "IMG_20261110_094549.png",
    "IMG_20261110_094605.png",
    "IMG_20261110_094617.png",
    "IMG_20261110_094629.png",
    "IMG_20261110_094642.png",
    "IMG_20261110_094700.png",
    "IMG_20261110_094712.png",
    "IMG_20261110_094725.png",
    "IMG_20261110_094740.png",
    "IMG_20261110_094752.png"
  ],
  "parry_10_frames": [
    "parry_01.png",
    "parry_02.png",
    "parry_03.png",
    "parry_04.png",
    "parry_05.png",
    "parry_06.png",
    "parry_07.png",
    "parry_08.png",
    "parry_09.png",
    "parry_10.png"
  ],
  "heal": [
    "IMG_20261110_092832.png",
    "IMG_20261110_092907.png",
    "IMG_20261110_092919.png",
    "IMG_20261110_092946.png",
    "IMG_20261110_092959.png",
    "IMG_20261110_093026.png",
    "IMG_20261110_093041.png",
    "IMG_20261110_093102.png",
    "IMG_20261110_093119.png",
    "IMG_20261110_093136.png"
  ],
  "ulti": [
    "frame_01.png",
    "frame_02.png",
    "frame_03.png",
    "frame_04.png",
    "frame_05.png",
    "frame_06.png",
    "frame_07.png",
    "frame_08.png",
    "frame_09.png",
    "frame_10.png"
  ]
}

static func _add_jaka_folder(frames: SpriteFrames, animation: String, folder: String, fps: float, top: int, height: int, canvas_width: int, white_threshold: float) -> void:
	frames.add_animation(animation)
	frames.set_animation_loop(animation, false)
	frames.set_animation_speed(animation, fps)
	for file: String in JAKA_FRAME_FILES[folder]:
		var path := "res://assets/Animasi Karakter/Jaka/" + folder + "/" + file
		var texture := load(path) as Texture2D
		if texture == null:
			push_error("Could not read Jaka's animation frame: " + path)
			continue
		var source := texture.get_image()
		if animation == "run":
			_remove_run_matte(source)
		var crop_height := source.get_height() if height == 0 else height
		var region := Rect2(0, top, source.get_width(), crop_height)
		var frame := _normalized(ImageTexture.create_from_image(source), region, 112.0, white_threshold < 1.0, canvas_width, white_threshold, animation in ["run", "walk"])
		frames.add_frame(animation, frame)

static var _cutouts: Dictionary = {}

static func cutout_texture(path: String) -> Texture2D:
	if _cutouts.has(path):
		return _cutouts[path]
	var source: Image = (load(path) as Texture2D).get_image()
	source.convert(Image.FORMAT_RGBA8)
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			var pixel := source.get_pixel(x, y)
			if minf(pixel.r, minf(pixel.g, pixel.b)) > 0.94:
				pixel.a = 0.0
				source.set_pixel(x, y, pixel)
	var texture := ImageTexture.create_from_image(source.get_region(source.get_used_rect()))
	_cutouts[path] = texture
	return texture

static func _remove_run_matte(source: Image) -> void:
	# The supplied running frames contain large, almost pure-black matte islands.
	# Remove only large connected black regions; preserve small dark line details.
	source.convert(Image.FORMAT_RGBA8)
	var width := source.get_width()
	var height := source.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	for y in range(height):
		for x in range(width):
			var index := y * width + x
			if visited[index] != 0:
				continue
			visited[index] = 1
			if not _is_run_matte(source.get_pixel(x, y)):
				continue
			var component: Array[Vector2i] = [Vector2i(x, y)]
			var cursor := 0
			while cursor < component.size():
				var at := component[cursor]
				cursor += 1
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = at + offset
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var next_index := next.y * width + next.x
					if visited[next_index] != 0:
						continue
					visited[next_index] = 1
					if _is_run_matte(source.get_pixelv(next)):
						component.append(next)
			if component.size() >= 500:
				for at in component:
					source.set_pixelv(at, Color.TRANSPARENT)

static func _is_run_matte(pixel: Color) -> bool:
	return pixel.a > 0.05 and maxf(pixel.r, maxf(pixel.g, pixel.b)) < 0.035

static func _keep_character_island(source: Image) -> void:
	# After matte removal, discard detached debris outside the character silhouette.
	var width := source.get_width()
	var height := source.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var largest: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			var index := y * width + x
			if visited[index] != 0:
				continue
			visited[index] = 1
			if source.get_pixel(x, y).a <= 0.01:
				continue
			var component: Array[Vector2i] = [Vector2i(x, y)]
			var cursor := 0
			while cursor < component.size():
				var at := component[cursor]
				cursor += 1
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = at + offset
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var next_index := next.y * width + next.x
					if visited[next_index] != 0:
						continue
					visited[next_index] = 1
					if source.get_pixelv(next).a > 0.01:
						component.append(next)
			if component.size() > largest.size():
				largest = component
	var mask := PackedByteArray()
	mask.resize(width * height)
	for at in largest:
		mask[at.y * width + at.x] = 1
	for y in range(height):
		for x in range(width):
			if mask[y * width + x] == 0:
				source.set_pixel(x, y, Color.TRANSPARENT)

static var _cat_frames: SpriteFrames
static var _villager_frames: Dictionary = {}

static func cat_frames() -> SpriteFrames:
	if _cat_frames != null:
		return _cat_frames
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_cat_strip(frames, "walk", "Jalan.png", [10,185,356,521,687,852,1016,1183,1347,1509], [173,343,511,678,841,1007,1172,1346,1501,1666], 390, 195, 12.0)
	_add_cat_strip(frames, "jump", "Lompat.png", [16,173,342,501,673,847,1030,1182,1362,1521], [160,329,495,666,834,1010,1171,1339,1505,1663], 338, 274, 14.0)
	_add_cat_strip(frames, "groom", "Menjilat.png", [9,172,332,496,665,828,992,1155,1327,1500], [167,326,483,652,817,974,1137,1309,1475,1650], 392, 222, 7.0)
	_cat_frames = frames
	return frames

static func _add_cat_strip(frames: SpriteFrames, animation: String, file: String, lefts: Array[int], rights: Array[int], top: int, height: int, fps: float) -> void:
	var sheet: Texture2D = load("res://assets/Animasi Karakter/Cuking/" + file)
	frames.add_animation(animation)
	frames.set_animation_loop(animation, true)
	frames.set_animation_speed(animation, fps)
	for index in range(lefts.size()):
		frames.add_frame(animation, _normalized(sheet, Rect2(lefts[index], top, rights[index] - lefts[index] + 1, height), 39.0, true, 60, 0.88, true))

static func villager_frames(variant: String) -> SpriteFrames:
	if _villager_frames.has(variant):
		return _villager_frames[variant]
	var file := "npc_cowo.png" if variant == "male" else "npc_,cewe.png"
	var lefts: Array = [22,198,351,529,680,846,1010,1164,1339,1514] if variant == "male" else [14,183,352,514,687,851,1012,1174,1336,1500]
	var rights: Array = [161,332,498,663,826,983,1155,1303,1477,1642] if variant == "male" else [157,322,494,669,833,986,1149,1306,1482,1638]
	var top := 260 if variant == "male" else 270
	var height := 420 if variant == "male" else 430
	var sheet: Texture2D = load("res://assets/Animasi Karakter/NPC/" + file)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 9.0)
	for index in range(lefts.size()):
		frames.add_frame("walk", _normalized(sheet, Rect2(lefts[index], top, rights[index] - lefts[index] + 1, height), 112.0, true, 90, 0.88, true))
	_villager_frames[variant] = frames
	return frames

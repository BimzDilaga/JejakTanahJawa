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

static func _normalized(texture: Texture2D, region: Rect2, height: float = 112.0, key_white: bool = false) -> Texture2D:
	# Normalize all animation frames to a common canvas and feet anchor.
	var source: Image = texture.get_image().get_region(Rect2i(region))
	if key_white:
		# The supplied shooting sheet has an opaque white backdrop. Key only pale
		# near-neutral pixels at runtime; the source PNG remains untouched.
		source.convert(Image.FORMAT_RGBA8)
		for y in range(source.get_height()):
			for x in range(source.get_width()):
				var pixel := source.get_pixel(x, y)
				var lightness := minf(pixel.r, minf(pixel.g, pixel.b))
				if lightness > 0.91 and maxf(pixel.r, maxf(pixel.g, pixel.b)) - lightness < 0.09:
					pixel.a = 0.0
					source.set_pixel(x, y, pixel)
	var factor: float = height / float(source.get_height())
	source.resize(maxi(1, roundi(source.get_width() * factor)), roundi(height), Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(90, 112, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	canvas.blit_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), Vector2i((90-source.get_width()) / 2, 112-source.get_height()))
	return ImageTexture.create_from_image(canvas)

static func jaka_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 1.0)
	var idle: Texture2D = load("res://assets/Karakter/Jaka.png") as Texture2D
	frames.add_frame("idle", _normalized(idle, REGIONS["Jaka.png"]))
	var paths: Dictionary = {
		"walk": "res://assets/Animasi Karakter/Jaka/Animasi_Jalan.png",
		"jump": "res://assets/Animasi Karakter/Jaka/Animasi_Lompat.png",
	}
	for animation: String in paths:
		frames.add_animation(animation)
		frames.set_animation_speed(animation, 12.0 if animation == "walk" else 10.0)
		frames.set_animation_loop(animation, animation == "walk")
		var sheet: Texture2D = load(paths[animation]) as Texture2D
		for index in range(10):
			var left: int = roundi(index * 217.2)
			var right: int = roundi((index + 1) * 217.2)
			var region: Rect2 = Rect2(left, 140, right - left, 470) if animation == "walk" else Rect2(left, 100, right - left, 500)
			frames.add_frame(animation, _normalized(sheet, region))
	frames.add_animation("shoot")
	frames.set_animation_speed("shoot", 28.0)
	frames.set_animation_loop("shoot", false)
	var shoot_sheet: Texture2D = load("res://assets/Animasi Karakter/Jaka/Animasi_Menembak.png") as Texture2D
	for index in range(10):
		var left: int = roundi(index * 217.2)
		var right: int = roundi((index + 1) * 217.2)
		frames.add_frame("shoot", _normalized(shoot_sheet, Rect2(left, 185, right - left, 380), 112.0, true))
	return frames

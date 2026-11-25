extends RefCounted
static var cache: Dictionary = {}

static func frames(kind: String) -> SpriteFrames:
	if cache.has(kind):
		return cache[kind]
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/boss_assets.json"))
	var result := SpriteFrames.new()
	result.remove_animation("default")
	for animation: String in manifest[kind]:
		result.add_animation(animation)
		result.set_animation_loop(animation,animation in ["idle","walk","run","flight","hover"])
		result.set_animation_speed(animation,10.0 if animation in ["walk","run"] else 12.0)
		for path: String in manifest[kind][animation].files:
			var texture := load(path) as Texture2D
			assert(texture!=null,path)
			result.add_frame(animation,texture)
	cache[kind] = result
	return result

static func effects(kind: String, animation: String) -> SpriteFrames:
	var key := kind+"/"+animation
	if cache.has(key):
		return cache[key]
	var source := frames(kind)
	var result := SpriteFrames.new()
	result.remove_animation("default")
	result.add_animation(animation)
	result.set_animation_speed(animation,12)
	result.set_animation_loop(animation,true)
	for index in range(source.get_frame_count(animation)):
		var image := source.get_frame_texture(animation,index)
		var atlas := AtlasTexture.new()
		atlas.atlas = image
		atlas.region = image.get_image().get_used_rect()
		result.add_frame(animation,atlas)
	cache[key] = result
	return result

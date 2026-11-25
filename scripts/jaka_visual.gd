extends RefCounted
## Prepared frames use one canvas and feet anchor in every animation.
const ROOT := "res://assets/Generated/Jaka/"
static var _frames: SpriteFrames

static func frames() -> SpriteFrames:
	if _frames != null:
		return _frames
	var result := SpriteFrames.new()
	result.remove_animation("default")
	_add(result, "walk", "walk", 8, 10.0, true)
	_add(result, "run", "run", 8, 14.0, true)
	_add(result, "heal", "heal", 8, 8.0 / 0.72, false)
	_add(result, "hurt", "hurt", 3, 3.0 / 0.22, false)
	_add(result, "parry", "parry", 6, 20.0, false)
	_add(result, "ultimate", "ultimate_clean", 8, 16.0, false)
	_add(result, "ultimate_wave", "ultimate_wave", 8, 16.0, false)
	_add(result, "keris_attack", "attack", 6, 6.0 / 0.34, false)
	_add(result, "chain_2", "chain_2", 6, 6.0/0.38, false)
	_add(result, "chain_3", "chain_3", 6, 6.0/0.44, false)
	_add(result, "idle", "idle", 1, 1.0, true)
	_add(result, "jump", "jump", 6, 10.0, false)
	_add(result, "stun", "reaction_1", 6, 12.0, false)
	_add(result, "death", "reaction_2", 6, 8.0, false)
	_add(result, "dash", "dash", 6, 6.0/0.18, false)
	_add(result, "backdash", "backdash", 6, 6.0/0.18, false)
	_frames = result
	return result

static func _add(result: SpriteFrames, animation: String, prefix: String, count: int, fps: float, loop: bool, first := 1) -> void:
	result.add_animation(animation)
	result.set_animation_speed(animation, fps)
	result.set_animation_loop(animation, loop)
	for index in range(first, first + count):
		var texture := load(ROOT + "%s_%02d.png" % [prefix, index]) as Texture2D
		assert(texture != null, "Run tools/prepare_jaka.gd before using the new Jaka art")
		result.add_frame(animation, texture)

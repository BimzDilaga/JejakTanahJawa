extends StaticBody2D
const Visual = preload("res://scripts/boss_visual.gd")
var target: CharacterBody2D
var arena: Node2D
var width := 180.0
var stand_seconds := 1.8
var warning_seconds := 0.6
var stood := 0.0
var collapse_time := -1.0
var fallen := false
var home := Vector2.ZERO
var collider: CollisionShape2D
var sprite: Sprite2D
var phase := 0

func _ready() -> void:
	add_to_group("trial_platforms")
	collision_layer = 1
	collision_mask = 0
	home = position
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width,20)
	collider = CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(width/2,10)
	collider.one_way_collision = true
	add_child(collider)
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	_show_phase(0)

func _physics_process(delta: float) -> void:
	if GameState.dialogue_active or GameState.ending_started or not is_instance_valid(target):
		return
	if fallen:
		position.y += (140.0+collapse_time*400.0)*delta
		collapse_time += delta
		sprite.modulate.a = maxf(0,1.0-collapse_time)
		if collapse_time>=1.5: set_physics_process(false)
		return
	var above := target.is_on_floor() and target.global_position.x>global_position.x-12 and target.global_position.x<global_position.x+width+12 and absf(target.global_position.y-global_position.y)<12
	if above:
		stood += delta
		if stood>=stand_seconds:
			trigger_collapse()
		elif stood>=stand_seconds*0.55 and phase<2:
			_show_phase(2)
		elif stood>=stand_seconds*0.2 and phase<1:
			_show_phase(1)
	if is_instance_valid(arena) and arena.chasing and home.x+width<target.position.x-110:
		trigger_collapse()
	if collapse_time>=0:
		collapse_time += delta
		sprite.position.x = width/2+sin(collapse_time*55)*2
		if collapse_time>=warning_seconds:
			fallen = true
			collapse_time = 0
			_show_phase(3)
			collider.set_deferred("disabled",true)
			if is_instance_valid(arena):
				arena.play_banaspati_sound("collapse",global_position)
				arena.player.effects.debris(global_position+Vector2(width/2,0),9,Color("a08b67"),1.2)
				arena.player.effects.dust(global_position+Vector2(width/2,0),0.8)

func trigger_collapse() -> void:
	if collapse_time>=0 or fallen:
		return
	collapse_time = 0
	_show_phase(2)
	if is_instance_valid(arena):
		arena.play_banaspati_sound("crack",global_position)
		arena.player.effects.dust(global_position+Vector2(width/2,0),0.4)

func reset_platform() -> void:
	set_physics_process(true)
	position = home
	stood = 0
	collapse_time = -1
	fallen = false
	collider.set_deferred("disabled",false)
	sprite.modulate = Color.WHITE
	_show_phase(0)

func _show_phase(value: int) -> void:
	phase = value
	var image: Texture2D = Visual.frames("banaspati").get_frame_texture("platform",phase)
	var used := image.get_image().get_used_rect()
	var atlas := AtlasTexture.new()
	atlas.atlas = image
	atlas.region = used
	sprite.texture = atlas
	sprite.scale = Vector2(width/used.size.x,0.42)
	sprite.position = Vector2(width/2,used.size.y*0.42/2-2)

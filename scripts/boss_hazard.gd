extends Node2D
const Visual = preload("res://scripts/boss_visual.gd")
var target: CharacterBody2D
var owner_boss: CharacterBody2D
var motion := Vector2.ZERO
var damage := 1
var parryable := true
var radius := 15.0
var lifetime := 5.0
var warning := 0.0
var age := 0.0
var ground_hazard := false
var hit := false
var effect_name := "fx_2"
var visual_kind := "banaspati"
var hazard_height := 130.0
var sprite: AnimatedSprite2D
var marker: AnimatedSprite2D
var _trail_time := 0.0
var _ignited := false
var knockback := 170.0

func _ready() -> void:
	add_to_group("trial_hazards")
	z_index = 4
	if visual_kind=="commander": return
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Visual.effects(visual_kind,effect_name)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.play(effect_name)
	sprite.frame_changed.connect(_align_sprite)
	add_child(sprite)
	_align_sprite()
	if warning>0 and ground_hazard:
		marker = AnimatedSprite2D.new()
		marker.sprite_frames = Visual.effects("banaspati","fx_1")
		marker.scale = Vector2(radius/32.0,0.28)
		marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		marker.play("fx_1")
		add_child(marker)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if GameState.dialogue_active:
		return
	if GameState.ending_started or not is_instance_valid(target):
		queue_free()
		return
	age += delta
	if age>=lifetime:
		queue_free()
		return
	if age<warning:
		if is_instance_valid(sprite): sprite.hide()
		queue_redraw()
		return
	if is_instance_valid(marker): marker.hide()
	if is_instance_valid(sprite): sprite.show()
	if not _ignited:
		_ignited = true
		if visual_kind=="commander" and is_instance_valid(owner_boss):
			owner_boss.arena.play_commander_sound("shot",global_position)
			target.effects.burst(global_position,4,Color("f7d080"),0.4,motion.normalized())
		if ground_hazard: target.effects.impact(global_position+Vector2(0,-10),Color("ffb75d"),0.65)
	_trail_time -= delta
	if _trail_time<=0:
		_trail_time = 0.065
		if visual_kind=="buto": target.effects.dust(global_position,0.3)
		elif visual_kind!="commander": target.effects.embers(global_position,2,-motion.normalized() if motion!=Vector2.ZERO else Vector2.UP)
	if not ground_hazard:
		var next := global_position+motion*delta
		var query := PhysicsRayQueryParameters2D.create(global_position,next,3)
		query.hit_from_inside = true
		var collision := get_world_2d().direct_space_state.intersect_ray(query)
		if not collision.is_empty():
			target.effects.impact(next,Color("ffd489"),0.45)
			var body: Node = collision.collider
			if body==target:
				_damage_target()
			queue_free()
			return
		global_position = next
		if global_position.distance_to(target.global_position+Vector2(0,-55))<radius+22:
			_damage_target()
			queue_free()
	else:
		global_position += motion*delta
		var offset := target.global_position-global_position
		if not hit and absf(offset.x)<radius+16 and offset.y>-hazard_height and offset.y<40:
			_damage_target()
	queue_redraw()

func _damage_target() -> void:
	if hit:
		return
	hit = true
	if visual_kind=="buto" and not parryable and target.parry_time>0 and target.invulnerable_time<=0:
		target.add_stance_load(2)
	var source_x := owner_boss.global_position.x if is_instance_valid(owner_boss) else global_position.x
	var deflected: bool = target.take_damage(damage,source_x,parryable,knockback)
	if deflected and is_instance_valid(owner_boss):
		owner_boss.on_parried()

func _align_sprite() -> void:
	if ground_hazard:
		sprite.position.y = -sprite.sprite_frames.get_frame_texture(effect_name,sprite.frame).get_height()/2.0

func _draw() -> void:
	if visual_kind=="commander":
		if age>=warning:
			var direction := motion.normalized()
			draw_line(-direction*10,direction*5,Color("ffe3a5"),3)
			draw_circle(direction*4,3,Color("fff2cd"))
		return
	if age<warning and ground_hazard:
		var pulse := 0.4+0.4*sin(age*18)
		draw_rect(Rect2(-radius,-4,radius*2,7),Color(1.0,0.35,0.1,pulse))
		draw_line(Vector2(-radius,-12),Vector2(radius,-12),Color("ffdc8b"),2)

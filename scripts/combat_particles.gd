extends Node2D
## World-space particles and impact flashes; art is drawn in code.
const LIMIT := 320
const FLASH_LIMIT := 12
var particles: Array[Dictionary] = []
var flashes: Array[Dictionary] = []
var random := RandomNumberGenerator.new()

func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	z_index = 5
	random.randomize()

func burst(at: Vector2, count: int, tint: Color, strength := 1.0, direction := Vector2.UP) -> void:
	for i in range(mini(count, LIMIT - particles.size())):
		var speed := random.randf_range(25.0, 100.0) * strength
		var motion := direction.rotated(random.randf_range(-1.1, 1.1)) * speed
		var life := random.randf_range(0.22, 0.55)
		particles.append({"at":at, "velocity":motion, "life":life, "total":life, "size":random.randf_range(1.5, 3.5), "tint":tint.lerp(Color.WHITE,0.35 if i%5==0 else 0.0), "kind":"spark", "gravity":180.0})
	queue_redraw()

func dust(at: Vector2, strength := 1.0, direction := 0.0) -> void:
	var count := clampi(roundi(10*strength),4,22)
	for i in range(mini(count,LIMIT-particles.size())):
		var life := random.randf_range(0.35,0.72)
		var motion := Vector2(random.randf_range(-65,65)+direction*30,random.randf_range(-45,-12))*strength
		var tint := Color("b5a081").lerp(Color("dac6a1"),random.randf())
		particles.append({"at":at+Vector2(random.randf_range(-8,8),-3),"velocity":motion,"life":life,"total":life,"size":random.randf_range(4,10)*strength,"tint":tint,"kind":"dust","gravity":-12.0})
	if strength>1.0:
		debris(at,roundi(4*strength),Color("9c886c"),strength)
	queue_redraw()

func debris(at: Vector2, count: int, tint: Color, strength := 1.0) -> void:
	for i in range(mini(count,LIMIT-particles.size())):
		var life := random.randf_range(0.35,0.7)
		particles.append({"at":at,"velocity":Vector2(random.randf_range(-95,95),random.randf_range(-150,-65))*strength,"life":life,"total":life,"size":random.randf_range(2,5),"tint":tint,"kind":"debris","gravity":420.0})

func embers(at: Vector2, count := 3, drift := Vector2.UP) -> void:
	for i in range(mini(count,LIMIT-particles.size())):
		var life := random.randf_range(0.3,0.7)
		particles.append({"at":at+Vector2(random.randf_range(-8,8),random.randf_range(-5,5)),"velocity":drift*random.randf_range(25,60)+Vector2(random.randf_range(-20,20),-15),"life":life,"total":life,"size":random.randf_range(1,3),"tint":Color("ffc675"),"kind":"ember","gravity":-35.0})

func impact(at: Vector2, tint := Color("ffe7a6"), strength := 1.0, parry := false) -> void:
	if flashes.size()>=FLASH_LIMIT: return
	flashes.append({"at":at,"life":0.18,"total":0.18,"tint":tint,"size":32.0*strength,"parry":parry})
	queue_redraw()

func clear() -> void:
	particles.clear()
	flashes.clear()
	queue_redraw()

func _process(delta: float) -> void:
	if GameState.dialogue_active:
		return
	for index in range(particles.size() - 1, -1, -1):
		var particle := particles[index]
		particle.life -= delta
		if particle.life <= 0.0:
			particles.remove_at(index)
			continue
		particle.velocity += Vector2(0, float(particle.gravity)) * delta
		if particle.kind=="dust": particle.velocity *= exp(-delta*2.0)
		particle.at += particle.velocity * delta
	for index in range(flashes.size()-1,-1,-1):
		flashes[index].life -= delta
		if flashes[index].life<=0: flashes.remove_at(index)
	queue_redraw()

func _draw() -> void:
	for particle in particles:
		var tint: Color = particle.tint
		var fade := float(particle.life)/float(particle.total)
		tint.a *= fade
		var size: float = particle.size
		var at: Vector2 = (particle.at as Vector2).round()
		if particle.kind=="dust":
			size *= 1.0+(1.0-fade)*1.7
			tint.a *= 0.25
			draw_rect(Rect2(at-Vector2(size,size*0.4),Vector2(size*2,size*0.8)),tint)
			draw_rect(Rect2(at-Vector2(size*0.65,size*0.7),Vector2(size*1.3,size*1.4)),tint)
		elif particle.kind=="debris":
			draw_colored_polygon(PackedVector2Array([at+Vector2(-size,0),at+Vector2(0,-size),at+Vector2(size,size*0.5),at+Vector2(-size*0.5,size)]),tint)
		else:
			var halo := tint
			halo.a *= 0.13
			draw_circle(at,size*2.5,halo)
			if particle.kind=="spark":
				var trail: Vector2 = (particle.velocity as Vector2).normalized()*minf(12.0,(particle.velocity as Vector2).length()*0.06)
				draw_line(at-trail,at,tint,maxf(1,size*0.65),false)
			draw_rect(Rect2(at,Vector2.ONE*size),tint)
	for flash in flashes:
		var fade: float = flash.life/flash.total
		var at: Vector2 = flash.at
		var tint: Color = flash.tint
		tint.a *= fade
		var radius: float = flash.size*(1.0-fade*0.45)
		var glow := tint
		glow.a *= 0.10
		draw_circle(at,radius,glow)
		draw_arc(at,radius,0,TAU,16,tint,1.5,false)
		for index in range(6 if flash.parry else 4):
			var direction := Vector2.RIGHT.rotated(index*TAU/(6 if flash.parry else 4)+0.4)
			draw_line(at-direction*radius*0.2,at+direction*radius,tint,2.0,false)

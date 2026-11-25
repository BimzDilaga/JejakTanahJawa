extends Node2D
## Code-native pixel sun/moon and a fixed, bounded star field behind scenery.
const STAR_COUNT := 48
var stars: Array[Vector3] = []
var sun_alpha := 0.0
var moon_alpha := 0.0
var sun_position := Vector2.ZERO
var moon_position := Vector2.ZERO
var elapsed := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	top_level = true
	z_index = -5
	global_transform = get_viewport().get_canvas_transform().affine_inverse()
	var random := RandomNumberGenerator.new()
	random.seed = 18251830
	for i in range(STAR_COUNT): stars.append(Vector3(random.randf_range(0.04,0.96),random.randf_range(0.03,0.40),random.randf_range(0.3,1.0)))
	update_time(GameState.time_of_day)

func update_time(time: float) -> void:
	var t := fposmod(time,1.0)
	sun_alpha = smoothstep(0.025,0.12,t)*(1.0-smoothstep(0.66,0.77,t))
	moon_alpha = 1.0-sun_alpha
	var progress := clampf(t/0.75,0,1)
	var size := get_viewport_rect().size
	sun_position = Vector2(lerpf(0.12,0.90,progress)*size.x,(0.30-sin(progress*PI)*0.14)*size.y).round()
	moon_position = Vector2(size.x*0.65,size.y*0.14).round()
	queue_redraw()

func _process(delta: float) -> void:
	global_transform = get_viewport().get_canvas_transform().affine_inverse()
	elapsed += delta
	if moon_alpha>0.01: queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	if moon_alpha>0.01:
		for star in stars:
			var at := Vector2(star.x*size.x,star.y*size.y).round()
			var alpha := moon_alpha*star.z*(0.72+0.28*sin(elapsed*0.55+star.z*20))
			draw_rect(Rect2(at,Vector2.ONE*(2 if star.z>0.75 else 1)),Color(0.78,0.86,1.0,alpha*0.7))
		_pixel_disc(moon_position,24,Color(0.91,0.94,0.85,moon_alpha),true)
	if sun_alpha>0.01:
		_pixel_disc(sun_position,26,Color(1.0,0.83,0.48,sun_alpha),false)

func _pixel_disc(center: Vector2, radius: int, tint: Color, crescent: bool) -> void:
	for ring in range(4,0,-1):
		var glow := tint
		glow.a *= 0.012
		draw_circle(center,radius+ring*9,glow)
	for y in range(-radius,radius+1,3):
		for x in range(-radius,radius+1,3):
			var point := Vector2(x,y)
			if point.length()>radius: continue
			if crescent and point.distance_to(Vector2(10,-4))<radius*0.88: continue
			var color := tint
			if crescent and (point.distance_to(Vector2(-13,9))<4 or point.distance_to(Vector2(-10,-11))<3): color = color.darkened(0.17)
			draw_rect(Rect2(center+point,Vector2(3,3)),color)

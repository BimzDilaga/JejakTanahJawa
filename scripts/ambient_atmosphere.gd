extends Node2D
## Layered motes and faint drifting mist, bounded around the camera.
const LIMIT := 80
var camera: Camera2D
var embers := false
var mist := true
var motes: Array[Dictionary] = []
var random := RandomNumberGenerator.new()
var elapsed := 0.0
var view := Rect2()
var heat := 0.0
var leaves: Array[Dictionary] = []
const LEAF_LIMIT := 10
var wooded := false

func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	z_index = 1
	process_mode = Node.PROCESS_MODE_PAUSABLE
	random.randomize()
	_bounds()
	for i in range(LIMIT): motes.append(_mote())
	if wooded:
		for i in range(LEAF_LIMIT): leaves.append({"at":Vector2(random.randf_range(view.position.x,view.end.x),random.randf_range(view.position.y,view.end.y)),"phase":random.randf_range(0,TAU)})

func _bounds() -> void:
	if not is_instance_valid(camera): return
	var size := get_viewport_rect().size/camera.zoom
	view = Rect2(camera.get_screen_center_position()-size/2-Vector2(150,100),size+Vector2(300,200))

func _mote() -> Dictionary:
	var depth := random.randf_range(0.35,1.0)
	return {"at":Vector2(random.randf_range(view.position.x,view.end.x),random.randf_range(view.position.y,view.end.y)),"depth":depth,"phase":random.randf_range(0,TAU),"speed":random.randf_range(5,16),"size":random.randf_range(0.8,2.0)*depth}

func _process(delta: float) -> void:
	if not is_instance_valid(camera): return
	elapsed += delta
	_bounds()
	for index in range(motes.size()):
		var mote := motes[index]
		mote.at += Vector2(5+sin(elapsed+mote.phase)*4,-float(mote.speed)*(1.7 if embers else 0.5))*delta*float(mote.depth)
		if not view.has_point(mote.at): motes[index] = _mote()
	for leaf in leaves:
		leaf.at += Vector2(18+sin(elapsed+float(leaf.phase))*7,12)*delta
		if not view.has_point(leaf.at): leaf.at = Vector2(view.position.x,random.randf_range(view.position.y,view.end.y))
	queue_redraw()

func _draw() -> void:
	if view.size==Vector2.ZERO: return
	var night := GameState.time_of_day>=0.75 or GameState.time_of_day<0.10
	for mote in motes:
		var at: Vector2 = (mote.at as Vector2).round()
		var pulse := 0.35+0.65*absf(sin(elapsed*0.7+float(mote.phase)))
		var tint := Color(1.0,0.65,0.29,0.48) if embers else Color(0.94,0.90,0.70,0.38 if night else 0.20)
		tint.a *= pulse*float(mote.depth)
		var size: float = mote.size
		if night or embers:
			var halo := tint
			halo.a *= 0.18
			draw_circle(at,size*3,halo)
		draw_rect(Rect2(at,Vector2.ONE*size),tint)
	if mist:
		for band in range(2):
			var center := view.position.y+view.size.y*(0.56+band*0.24)
			var points := PackedVector2Array()
			for index in range(13):
				var x := view.position.x+index*view.size.x/12
				points.append(Vector2(x,center+sin(x*0.004+elapsed*0.15+band)*19))
			for index in range(12,-1,-1):
				var x := view.position.x+index*view.size.x/12
				points.append(Vector2(x,center+65+sin(x*0.004+elapsed*0.15+band)*19))
			var tint := Color(0.51,0.65,0.68,0.028 if night else 0.014)
			if embers: tint = Color(0.48,0.19,0.08,0.018+heat*0.012)
			draw_colored_polygon(points,tint)
	for leaf in leaves:
		var at: Vector2 = (leaf.at as Vector2).round()
		var span := Vector2(3+absf(sin(elapsed+float(leaf.phase)))*3,2)
		draw_line(at-span,at+span,Color(0.53,0.50,0.29,0.22),2)

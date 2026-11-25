extends CanvasLayer
## World-only grading, below UI layer 10 and above sky layer -10/world layer 0.
const FILTER_SHADER = preload("res://shaders/day_night.gdshader")
const PHASE_NAMES := ["Pagi", "Siang", "Sore", "Malam"]
const GRADES := [
	{"tint":Color(1.03,1.0,0.92), "exposure":1.02, "saturation":0.95, "lift":Color(0.012,0.009,0.003)},
	{"tint":Color(1.0,1.0,1.0), "exposure":1.04, "saturation":1.02, "lift":Color(0.0,0.0,0.0)},
	{"tint":Color(1.14,0.91,0.74), "exposure":0.92, "saturation":0.95, "lift":Color(0.012,0.004,0.0)},
	{"tint":Color(0.68,0.80,1.05), "exposure":0.72, "saturation":0.78, "lift":Color(0.027,0.040,0.062)},
]

var chapter: Node
var clock_enabled := true
var phase_label: Label
var filter_rect: ColorRect
var filter_material: ShaderMaterial
var _last_time := -1.0
var sky: Node2D

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	sky = preload("res://scripts/sky_atmosphere.gd").new()
	sky.name = "CelestialSky"
	chapter.world.add_child(sky)
	filter_rect = ColorRect.new()
	filter_rect.name = "WorldTimeFilter"
	filter_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	filter_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filter_material = ShaderMaterial.new()
	filter_material.shader = FILTER_SHADER
	filter_rect.material = filter_material
	add_child(filter_rect)
	apply_time()

func _process(delta: float) -> void:
	if can_advance():
		GameState.advance_day_time(delta)
	apply_time()
	if is_instance_valid(chapter) and is_instance_valid(chapter.player):
		var origin: Vector2 = get_viewport().get_canvas_transform()*(chapter.player.global_position+Vector2(0,-55))
		filter_material.set_shader_parameter("player_origin",origin/get_viewport().get_visible_rect().size)

func can_advance() -> bool:
	if not clock_enabled:
		return false
	if get_tree().paused or GameState.dialogue_active or GameState.ending_started:
		return false
	if not is_instance_valid(chapter) or not is_instance_valid(chapter.player):
		return false
	return chapter.player.controls_enabled and not chapter.player.dead and chapter.stage in [chapter.Stage.EXPLORE,chapter.Stage.WARNING,chapter.Stage.AFTERMATH,chapter.Stage.EXIT]

static func phase_index(time: float) -> int:
	return clampi(int(fposmod(time,1.0) * 4.0),0,3)

static func phase_name(time: float) -> String:
	return PHASE_NAMES[phase_index(time)]

static func sample_grade(time: float) -> Dictionary:
	# Four phase centers; interpolate cyclically, including night back to morning.
	var position := fposmod(time - 0.125,1.0) * 4.0
	var first := int(position)
	var second := (first + 1) % 4
	var weight := smoothstep(0.0,1.0,position - first)
	var start: Dictionary = GRADES[first]
	var finish: Dictionary = GRADES[second]
	return {
		"tint":(start.tint as Color).lerp(finish.tint,weight),
		"exposure":lerpf(start.exposure,finish.exposure,weight),
		"saturation":lerpf(start.saturation,finish.saturation,weight),
		"lift":(start.lift as Color).lerp(finish.lift,weight),
		"night":lerpf(1.0 if first==3 else 0.0,1.0 if second==3 else 0.0,weight),
	}

func apply_time() -> void:
	if GameState.time_of_day == _last_time:
		return
	_last_time = GameState.time_of_day
	sky.update_time(_last_time)
	var grade := sample_grade(_last_time)
	var tint: Color = grade.tint
	var lift: Color = grade.lift
	filter_material.set_shader_parameter("tint",Vector3(tint.r,tint.g,tint.b))
	filter_material.set_shader_parameter("exposure",grade.exposure)
	filter_material.set_shader_parameter("saturation",grade.saturation)
	filter_material.set_shader_parameter("shadow_lift",Vector3(lift.r,lift.g,lift.b))
	filter_material.set_shader_parameter("night_strength",grade.night)
	if is_instance_valid(phase_label):
		phase_label.text = phase_name(_last_time).to_upper()

func _unhandled_input(event: InputEvent) -> void:
	# Editor/debug preview only; release builds keep the automatic cycle.
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F6:
		GameState.time_of_day = fposmod((phase_index(GameState.time_of_day) + 1) * 0.25 + 0.125,1.0)
		apply_time()
		get_viewport().set_input_as_handled()

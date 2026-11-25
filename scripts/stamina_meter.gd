extends Control
var player: CharacterBody2D
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
	if not is_instance_valid(player): return
	draw_rect(Rect2(Vector2.ZERO,size),Color("142b2af2"))
	draw_rect(Rect2(7,5,size.x-14,size.y-10),Color("364a40"))
	var tint := Color("e5a46e") if player.stamina_warning>0 else Color("83b88b")
	draw_rect(Rect2(7,5,(size.x-14)*player.stamina/player.max_stamina,size.y-10),tint)
	draw_string(ThemeDB.fallback_font,Vector2(12,17),"STAMINA  %d/%d" % [roundi(player.stamina),roundi(player.max_stamina)],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("fff2d4"))

extends Node2D
## Small code-native set dressing, no replacement of the supplied artwork.
func _draw() -> void:
	# Warm footpath, roadside stakes and directional gate.
	draw_rect(Rect2(0,552,3800,18),Color("847344"))
	for x in range(80,3800,141):
		draw_line(Vector2(x,561),Vector2(x+42,561),Color("ad9862"),2)
	for x in [520,580,640]:
		draw_rect(Rect2(x,516,8,48),Color("554329"))
		draw_colored_polygon(PackedVector2Array([Vector2(x+8,518),Vector2(x+34,522),Vector2(x+8,535)]),Color("d2b278"))
	for x in [3320,3660]:
		draw_rect(Rect2(x,422,16,142),Color("554329"))
		draw_rect(Rect2(x-3,422,22,14),Color("b49a65"))
	draw_rect(Rect2(3310,391,380,42),Color("243b2b"))
	# Soft ground shadows beneath the two stationary villagers.
	for x in [900,1510]:
		draw_ellipse_shadow(Vector2(x,567))

func draw_ellipse_shadow(at: Vector2) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := i * TAU / 24.0
		points.append(at+Vector2(cos(angle)*34,sin(angle)*5))
	draw_colored_polygon(points,Color(0.10,0.15,0.09,0.3))

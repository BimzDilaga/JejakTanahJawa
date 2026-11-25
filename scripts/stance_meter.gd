extends Control
## Temporary HUD artwork; replace its appearance without changing combat rules.
var player: CharacterBody2D
var title: Label
var status: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title = Label.new()
	title.position = Vector2(12, 5)
	title.add_theme_font_size_override("font_size", 14)
	add_child(title)
	status = Label.new()
	status.position = Vector2(12, 45)
	status.add_theme_font_size_override("font_size", 13)
	add_child(status)

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	title.text = "KLIK KANAN  %d / %d" % [player.stance, player.STANCE_MAX]
	status.text = player.parry_status()+" | Dash "+("%.1f" % player.dash_cooldown if player.dash_cooldown>0 else "siap")
	status.modulate = Color("ffbe8f") if player.stance >= 4 or player.stun_time > 0.0 else Color("d6dfcc")
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(player):
		return
	draw_style_box(_panel(), Rect2(Vector2.ZERO, size))
	for index in range(player.STANCE_MAX):
		var color := Color("d7b56c") if index < player.stance else Color("3e554d")
		if index < player.stance and player.stance >= 4:
			color = Color("e79b64")
		draw_rect(Rect2(12 + index * 40, 30, 32, 7), color)
	if player.stance > 0 and player.parry_time <= 0.0:
		var fraction := clampf(player.stance_recovery_time / player.STANCE_RECOVERY_INTERVAL, 0, 1)
		draw_rect(Rect2(12, 40, 192 * fraction, 2), Color("b6d7a7"))

func _panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("142b2aeb")
	style.border_color = Color("6c7d61")
	style.set_border_width_all(1)
	return style

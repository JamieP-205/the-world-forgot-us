class_name RestRecorderVisual
extends Control
## Physical tape-deck readout used during rest and voice separation.

var decoding := false
var progress := 0.0
var elapsed := 0.0


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_style_box(_panel_style(), rect)
	var centre_y := size.y * 0.53
	var left_reel := Vector2(82.0, centre_y)
	var right_reel := Vector2(size.x - 82.0, centre_y)
	_draw_reel(left_reel, 31.0, elapsed * (2.4 if decoding else 0.35))
	_draw_reel(right_reel, 31.0, -elapsed * (2.8 if decoding else 0.30))
	draw_line(left_reel + Vector2(28, -8), right_reel + Vector2(-28, -8),
		Color(0.35, 0.31, 0.22, 0.72), 2.0)
	draw_line(left_reel + Vector2(28, 8), right_reel + Vector2(-28, 8),
		Color(0.20, 0.18, 0.14, 0.72), 2.0)

	var meter := Rect2(Vector2(138, 18), Vector2(maxf(size.x - 276.0, 1.0), 48))
	draw_rect(meter, Color(0.025, 0.052, 0.049, 0.96))
	draw_rect(meter, Color(0.26, 0.48, 0.44, 0.68), false, 1.0)
	var usable := meter.size.x - 16.0
	var fill_width := usable * clampf(progress / 100.0, 0.0, 1.0)
	draw_rect(Rect2(meter.position + Vector2(8, meter.size.y - 12), Vector2(fill_width, 3)),
		Color(0.78, 0.52, 0.22, 0.92))
	var font := ThemeDB.fallback_font
	var label := "VOICE / CARRIER SEPARATION" if decoding else "RECEIVER MONITOR"
	draw_string(font, meter.position + Vector2(9, 19), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.55, 0.76, 0.70, 0.92))
	draw_string(font, meter.position + Vector2(9, 36), "%03d%%" % roundi(progress),
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.80, 0.68, 0.43, 0.92))


func _draw_reel(centre: Vector2, radius: float, angle: float) -> void:
	draw_circle(centre, radius + 5.0, Color(0.055, 0.062, 0.058, 1.0))
	draw_arc(centre, radius + 5.0, 0.0, TAU, 48, Color(0.44, 0.34, 0.21, 0.88), 2.0)
	draw_circle(centre, radius, Color(0.17, 0.16, 0.13, 1.0))
	draw_circle(centre, 8.0, Color(0.035, 0.042, 0.04, 1.0))
	for spoke in 5:
		var spoke_angle := angle + float(spoke) * TAU / 5.0
		var inner := centre + Vector2.from_angle(spoke_angle) * 9.0
		var outer := centre + Vector2.from_angle(spoke_angle) * 26.0
		draw_line(inner, outer, Color(0.58, 0.49, 0.34, 0.86), 4.0)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.058, 0.052, 1.0)
	style.border_color = Color(0.29, 0.24, 0.16, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style

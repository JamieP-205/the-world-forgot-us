extends Control

var beat := 0
var elapsed := 0.0


func set_beat(index: int) -> void:
	beat = index
	elapsed = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.01, 0.009, 1.0))
	if beat == 0:
		_draw_static(w, h, 0.018)
	elif beat == 1:
		_draw_carriage(w, h)
	elif beat == 2:
		_draw_sign(w, h)
	elif beat == 3:
		_draw_tape(w, h)
	elif beat == 4:
		_draw_tower(w, h)
	else:
		_draw_road(w, h)
	_draw_static(w, h, 0.025)


func _draw_carriage(w: float, h: float) -> void:
	var window := Rect2(w * 0.12, h * 0.13, w * 0.48, h * 0.46)
	draw_rect(window, Color(0.045, 0.055, 0.051, 1.0))
	for pane in 4:
		var x := window.position.x + pane * window.size.x / 4.0
		draw_line(Vector2(x, window.position.y), Vector2(x + 8, window.end.y), Color(0.14, 0.16, 0.14, 0.8), 5.0)
	# Cold dawn catches one edge of the abandoned carriage.
	draw_colored_polygon(PackedVector2Array([
		Vector2(window.position.x, window.end.y), Vector2(window.end.x, window.position.y),
		Vector2(window.end.x, window.end.y),
	]), Color(0.23, 0.32, 0.31, 0.16))
	var table := Rect2(w * 0.58, h * 0.58, w * 0.25, 12)
	draw_rect(table, Color(0.22, 0.19, 0.13, 0.92))
	draw_rect(Rect2(w * 0.64, h * 0.48, 128, 72), Color(0.07, 0.085, 0.079, 1.0))
	draw_rect(Rect2(w * 0.655, h * 0.5, 78, 22), Color(0.12, 0.16, 0.15, 1.0))
	draw_circle(Vector2(w * 0.75, h * 0.52), 11, Color(0.57, 0.42, 0.22, 0.72))
	# The cable ends visibly short of the socket.
	var cable := PackedVector2Array([
		Vector2(w * 0.72, h * 0.57), Vector2(w * 0.75, h * 0.64),
		Vector2(w * 0.82, h * 0.66), Vector2(w * 0.86, h * 0.62),
	])
	draw_polyline(cable, Color(0.15, 0.17, 0.15, 1), 4.0)
	draw_circle(Vector2(w * 0.87, h * 0.615), 5.0, Color(0.46, 0.34, 0.2, 0.9))


func _draw_sign(w: float, h: float) -> void:
	var post_x := w * 0.48
	draw_line(Vector2(post_x, h * 0.18), Vector2(post_x, h * 0.82), Color(0.18, 0.18, 0.14, 1), 10.0)
	var jitter := sin(elapsed * 8.0) * 5.0
	_draw_arrow_sign(Vector2(post_x - 285, h * 0.28 + jitter), Vector2(310, 66), "NORTH / SHELTERS", true)
	_draw_arrow_sign(Vector2(post_x - 8, h * 0.44 - jitter), Vector2(350, 66), "SOUTH / EXCHANGE", false)
	_draw_arrow_sign(Vector2(post_x - 250, h * 0.61 + jitter * 0.5), Vector2(285, 66), "EVACUATION", true)
	for arc in 5:
		draw_arc(Vector2(post_x + 38, h * 0.22), 28 + arc * 18, -2.2, 0.55, 24, Color(0.33, 0.78, 0.77, 0.16), 1.3)


func _draw_arrow_sign(position: Vector2, dimensions: Vector2, text: String, left: bool) -> void:
	var rect := Rect2(position, dimensions)
	draw_rect(rect, Color(0.36, 0.32, 0.19, 0.92))
	var tip_x := rect.position.x - 28 if left else rect.end.x + 28
	var base_x := rect.position.x if left else rect.end.x
	draw_colored_polygon(PackedVector2Array([
		Vector2(base_x, rect.position.y), Vector2(tip_x, rect.position.y + rect.size.y * 0.5),
		Vector2(base_x, rect.end.y),
	]), Color(0.36, 0.32, 0.19, 0.92))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(25, 41), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.82, 0.76, 0.55, 1))


func _draw_tape(w: float, h: float) -> void:
	var tilt := sin(elapsed * 0.3) * 0.01
	var centre := Vector2(w * 0.5, h * 0.43)
	var tape := Transform2D(tilt, centre)
	var body := PackedVector2Array([
		Vector2(-245, -105), Vector2(245, -105), Vector2(245, 105), Vector2(-245, 105)
	])
	for i in body.size(): body[i] = tape * body[i]
	draw_colored_polygon(body, Color(0.13, 0.14, 0.12, 1.0))
	draw_rect(Rect2(centre + Vector2(-205, -70), Vector2(410, 100)), Color(0.66, 0.61, 0.43, 0.92))
	draw_circle(centre + Vector2(-112, 58), 32, Color(0.035, 0.04, 0.036, 1))
	draw_circle(centre + Vector2(112, 58), 32, Color(0.035, 0.04, 0.036, 1))
	draw_string(ThemeDB.fallback_font, centre + Vector2(-175, -18), "ELLIE - DO NOT ANSWER ME", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color(0.12, 0.105, 0.075, 1))
	draw_string(ThemeDB.fallback_font, centre + Vector2(-118, 13), "14B / M. WARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.19, 0.16, 0.1, 1))


func _draw_tower(w: float, h: float) -> void:
	var base := Vector2(w * 0.62, h * 0.82)
	var top := Vector2(w * 0.62, h * 0.13)
	for i in 7:
		var t := float(i) / 6.0
		var y := lerpf(base.y, top.y, t)
		var half := lerpf(100.0, 12.0, t)
		draw_line(Vector2(base.x - half, y), Vector2(base.x + half, y), Color(0.15, 0.17, 0.15, 1), 3.0)
		if i < 6:
			var next_t := float(i + 1) / 6.0
			var next_y := lerpf(base.y, top.y, next_t)
			var next_half := lerpf(100.0, 12.0, next_t)
			draw_line(Vector2(base.x - half, y), Vector2(base.x + next_half, next_y), Color(0.12, 0.14, 0.13, 1), 3.0)
			draw_line(Vector2(base.x + half, y), Vector2(base.x - next_half, next_y), Color(0.12, 0.14, 0.13, 1), 3.0)
	var pulse := 0.45 + sin(elapsed * 3.0) * 0.22
	draw_circle(top, 8, Color(0.95, 0.43, 0.23, pulse))
	for ring in 4:
		draw_arc(top, 34 + ring * 42 + sin(elapsed * 1.4 + ring) * 4, -2.8, -0.34, 42, Color(0.32, 0.77, 0.76, 0.21 - ring * 0.035), 1.4)
	draw_string(ThemeDB.fallback_font, Vector2(w * 0.12, h * 0.26), "02:17", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color(0.79, 0.49, 0.23, 0.78))
	draw_string(ThemeDB.fallback_font, Vector2(w * 0.12, h * 0.32), "TOLLARD EXCHANGE / CARRIER WAKE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.39, 0.61, 0.58, 0.82))


func _draw_road(w: float, h: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.43, h), Vector2(w * 0.57, h), Vector2(w * 0.515, h * 0.18), Vector2(w * 0.485, h * 0.18)
	]), Color(0.07, 0.076, 0.066, 1))
	for i in 8:
		var y := h * (0.88 - i * 0.095)
		var width := 34.0 * (1.0 - i / 10.0)
		draw_line(Vector2(w * 0.5 - width * 0.12, y), Vector2(w * 0.5 + width * 0.12, y - 18), Color(0.65, 0.55, 0.31, 0.34), 3.0)
	for side in [-1, 1]:
		var x: float = w * (0.5 + float(side) * 0.24)
		draw_line(Vector2(x, h * 0.78), Vector2(x, h * 0.3), Color(0.09, 0.11, 0.1, 1), 5.0)


func _draw_static(w: float, h: float, alpha: float) -> void:
	for line in 34:
		var y := fmod(line * 47.0 + elapsed * (5.0 + line % 3), h)
		draw_line(Vector2(0, y), Vector2(w, y + sin(line) * 2.0), Color(0.55, 0.62, 0.55, alpha), 1.0)

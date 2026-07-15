extends Control
## Schematic paper map: deliberately marks regions and known landmarks, never
## the player's exact position. Ellie has road notes, not a working GPS.

var region_index := 1
var visited_through := 1

const STOPS := [
	{"name": "CARRIAGE 317", "short": "HOME", "p": Vector2(0.09, 0.70)},
	{"name": "CULLBROOK", "short": "A38", "p": Vector2(0.27, 0.57)},
	{"name": "ASHMERE", "short": "ESTATE", "p": Vector2(0.47, 0.40)},
	{"name": "WRENFIELD", "short": "RELAYS", "p": Vector2(0.68, 0.51)},
	{"name": "TOLLARD", "short": "EXCHANGE", "p": Vector2(0.89, 0.26)},
]


func set_progress(current: int, reached: int) -> void:
	region_index = clampi(current, 0, STOPS.size() - 1)
	visited_through = clampi(reached, 0, STOPS.size() - 1)
	queue_redraw()


func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return
	var high_contrast := SettingsManager.get_bool("accessibility", "high_contrast")
	draw_rect(
		Rect2(Vector2.ZERO, size),
		Color(0.018, 0.021, 0.018, 0.99) if high_contrast else Color(0.055, 0.057, 0.049, 0.96)
	)
	# Faint ruled-paper lines and hand-drawn cross streets.
	for row in 8:
		var y := size.y * (0.1 + row * 0.105)
		draw_line(Vector2(0, y), Vector2(size.x, y + sin(row * 1.7) * 5.0), Color(0.58, 0.54, 0.42, 0.07), 1.0)
	for mark in 13:
		var x := size.x * (0.05 + float(mark) * 0.075)
		var y0 := size.y * (0.16 + fmod(mark * 0.27, 0.63))
		draw_line(Vector2(x - 18, y0), Vector2(x + 34, y0 + 15), Color(0.43, 0.49, 0.43, 0.08), 1.0)

	var points := PackedVector2Array()
	for stop in STOPS:
		points.append(Vector2(stop.p.x * size.x, stop.p.y * size.y))
	for i in points.size() - 1:
		var used := i < visited_through
		var used_ink := Color(1.0, 0.72, 0.26, 1.0) if high_contrast else Color(0.76, 0.55, 0.25, 0.78)
		var unknown_ink := Color(0.58, 0.71, 0.64, 0.78) if high_contrast else Color(0.35, 0.42, 0.38, 0.48)
		draw_dashed_line(points[i], points[i + 1], used_ink if used else unknown_ink, 3.0 if high_contrast else 2.0, 9.0)

	var font := ThemeDB.fallback_font
	for i in STOPS.size():
		var point := points[i]
		var known := i <= visited_through
		var current := i == region_index
		var ink := Color(1.0, 0.77, 0.3, 1.0) if current else (
			(Color(0.78, 1.0, 0.91, 1.0) if known else Color(0.55, 0.66, 0.6, 1.0))
			if high_contrast else
			(Color(0.62, 0.75, 0.68, 0.92) if known else Color(0.32, 0.36, 0.33, 0.9))
		)
		if current:
			draw_circle(point, 13.0, Color(0.9, 0.58, 0.19, 0.14))
			draw_arc(point, 14.0, 0, TAU, 28, ink, 1.5)
		draw_circle(point, 4.5 if current else 3.0, ink)
		draw_string(font, point + Vector2(-18, -13), String(STOPS[i].short), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, ink)
		draw_string(font, point + Vector2(-28, 25), String(STOPS[i].name), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, ink.darkened(0.08))

	# North is a note, not a decorative compass widget.
	draw_line(Vector2(size.x - 34, 40), Vector2(size.x - 34, 14), Color(0.7, 0.69, 0.57, 0.72), 1.5)
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x - 34, 9), Vector2(size.x - 39, 19), Vector2(size.x - 29, 19)
	]), Color(0.7, 0.69, 0.57, 0.72))
	draw_string(font, Vector2(size.x - 39, 54), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.69, 0.57, 0.72))

extends Control
## Schematic paper map: deliberately marks regions and known landmarks, never
## the player's exact position. Ellie has road notes, not a working GPS.

var region_index := 1
var visited_through := 1
var _ui_scale := 1.0

const STOPS := [
	{"name": "Carriage 317", "short": "HOME", "p": Vector2(0.09, 0.70)},
	{"name": "Cullbrook", "short": "A38", "p": Vector2(0.27, 0.57)},
	{"name": "Ashmere", "short": "ESTATE", "p": Vector2(0.47, 0.40)},
	{"name": "Wrenfield", "short": "RELAYS", "p": Vector2(0.68, 0.51)},
	{"name": "Tollard", "short": "EXCHANGE", "p": Vector2(0.89, 0.26)},
]


func set_progress(current: int, reached: int) -> void:
	region_index = clampi(current, 0, STOPS.size() - 1)
	visited_through = clampi(reached, 0, STOPS.size() - 1)
	queue_redraw()


func set_ui_scale(value: float) -> void:
	_ui_scale = clampf(value, 1.0, 3.2)
	queue_redraw()


func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return
	var high_contrast := SettingsManager.get_bool("accessibility", "high_contrast")
	draw_rect(Rect2(Vector2.ZERO, size),
		Color(0.93, 0.89, 0.72, 1.0) if high_contrast else Color(0.63, 0.60, 0.49, 0.66))
	draw_rect(Rect2(2, 2, size.x - 4, size.y - 4), Color(0.19, 0.22, 0.18, 0.42), false, 1.0)
	# Faint ruled-paper lines and hand-drawn cross streets.
	for row in 8:
		var y := size.y * (0.1 + row * 0.105)
		draw_line(Vector2(0, y), Vector2(size.x, y + sin(row * 1.7) * 5.0), Color(0.14, 0.19, 0.17, 0.09), 1.0)
	for mark in 13:
		var x := size.x * (0.05 + float(mark) * 0.075)
		var y0 := size.y * (0.16 + fmod(mark * 0.27, 0.63))
		draw_line(Vector2(x - 18, y0), Vector2(x + 34, y0 + 15), Color(0.14, 0.24, 0.21, 0.11), 1.0)

	var points := PackedVector2Array()
	for stop in STOPS:
		points.append(Vector2(stop.p.x * size.x, stop.p.y * size.y))
	for i in points.size() - 1:
		var used := i < visited_through
		var used_ink := Color(0.62, 0.25, 0.05, 1.0) if high_contrast else Color(0.44, 0.27, 0.1, 0.86)
		var unknown_ink := Color(0.09, 0.24, 0.2, 0.82) if high_contrast else Color(0.16, 0.25, 0.21, 0.54)
		draw_dashed_line(points[i], points[i + 1], used_ink if used else unknown_ink, 3.0 if high_contrast else 2.0, 9.0)

	var font := ThemeDB.fallback_font
	var ui := _ui_scale
	for i in STOPS.size():
		var point := points[i]
		var known := i <= visited_through
		var current := i == region_index
		var ink := Color(0.58, 0.24, 0.04, 1.0) if current else (
			(Color(0.04, 0.2, 0.16, 1.0) if known else Color(0.27, 0.32, 0.27, 1.0))
			if high_contrast else
			(Color(0.11, 0.25, 0.21, 0.94) if known else Color(0.27, 0.29, 0.24, 0.86))
		)
		if current:
			draw_circle(point, 13.0 * ui, Color(0.58, 0.25, 0.05, 0.13))
			draw_arc(point, 14.0 * ui, 0, TAU, 28, ink, 1.5 * ui)
		draw_circle(point, (4.5 if current else 3.0) * ui, ink)
		draw_string(font, point + Vector2(-18, -13) * ui, String(STOPS[i].short), HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(10.0 * ui), ink)
		draw_string(font, point + Vector2(-28, 25) * ui, String(STOPS[i].name), HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(9.0 * ui), ink.darkened(0.08))

	# North is a note, not a decorative compass widget.
	draw_line(Vector2(size.x - 34 * ui, 40 * ui), Vector2(size.x - 34 * ui, 14 * ui), Color(0.12, 0.22, 0.18, 0.72), 1.5 * ui)
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x - 34 * ui, 9 * ui), Vector2(size.x - 39 * ui, 19 * ui), Vector2(size.x - 29 * ui, 19 * ui)
	]), Color(0.12, 0.22, 0.18, 0.72))
	draw_string(font, Vector2(size.x - 39 * ui, 54 * ui), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(10.0 * ui), Color(0.12, 0.22, 0.18, 0.72))

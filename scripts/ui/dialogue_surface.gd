extends Control
## Draws the repaired receiver and paper transcript beneath dialogue copy.

const SOOT := Color("111715")
const METAL := Color("2b302c")
const PAPER := Color("c9bea0")
const PAPER_EDGE := Color("81775f")
const AMBER := Color("d38a36")
const CYAN := Color("58b8b8")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x < 40.0 or size.y < 40.0:
		return
	# A slightly skewed shadow keeps the card from reading like a web modal.
	draw_colored_polygon(PackedVector2Array([
		Vector2(13, 17), Vector2(size.x - 3, 8),
		Vector2(size.x - 10, size.y), Vector2(5, size.y - 5),
	]), Color(0, 0, 0, 0.62))
	draw_rect(Rect2(0, 0, size.x - 12, size.y - 10), SOOT, true)
	draw_rect(Rect2(0, 0, size.x - 12, size.y - 10), Color(METAL, 0.82), false, 1.0)
	draw_rect(Rect2(0, 0, 5, size.y - 10), AMBER, true)

	# The spoken line is printed on a replaceable, stained receiver slip.
	var paper_top := minf(92.0, size.y * 0.36)
	var paper_bottom := maxf(paper_top + 64.0, size.y - 62.0)
	var paper := PackedVector2Array([
		Vector2(17, paper_top + 3), Vector2(size.x - 31, paper_top),
		Vector2(size.x - 28, paper_bottom - 5), Vector2(size.x - 44, paper_bottom),
		Vector2(size.x - 58, paper_bottom + 4), Vector2(29, paper_bottom),
		Vector2(15, paper_bottom - 7),
	])
	draw_colored_polygon(paper, PAPER)
	draw_polyline(PackedVector2Array([paper[0], paper[1], paper[2]]), PAPER_EDGE, 1.0)
	for mark in 5:
		var y := paper_top + 19.0 + float(mark) * 23.0
		if y >= paper_bottom - 8.0:
			break
		draw_line(Vector2(28, y), Vector2(size.x - 46, y + float(mark % 2)), Color(0.28, 0.29, 0.24, 0.075), 1.0)

	# Masking tape and physical screws sell the field repair without decoration.
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x * 0.44, paper_top - 7), Vector2(size.x * 0.58, paper_top - 9),
		Vector2(size.x * 0.59, paper_top + 7), Vector2(size.x * 0.43, paper_top + 9),
	]), Color(0.73, 0.66, 0.47, 0.58))
	for screw in [Vector2(15, 14), Vector2(size.x - 27, 14)]:
		draw_circle(screw, 3.5, Color(0.42, 0.43, 0.37, 1))
		draw_line(screw - Vector2(2, 0), screw + Vector2(2, 0), Color(0.12, 0.14, 0.13, 1), 1.0)

	var meter_y := 44.0
	draw_line(Vector2(size.x - 224, meter_y), Vector2(size.x - 40, meter_y), Color(CYAN, 0.24), 1.0)
	for tick in 9:
		var x := size.x - 216.0 + float(tick) * 20.0
		var height := 3.0 + float((tick * 7) % 5)
		draw_line(Vector2(x, meter_y - height), Vector2(x, meter_y + height), Color(CYAN, 0.54), 1.0)

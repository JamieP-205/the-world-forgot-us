class_name CraftingWorkbenchSurface
extends Control
## Draws the workbench beneath the functional controls. The fixed marks,
## timber joins, tape and dog-eared paper keep the screen feeling handled
## rather than assembled from interchangeable UI cards.

var _vertical_pages := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_vertical_pages(vertical: bool) -> void:
	if _vertical_pages == vertical:
		return
	_vertical_pages = vertical
	queue_redraw()


func _draw() -> void:
	var full := Rect2(Vector2.ZERO, size)
	draw_rect(full, Color(0.005, 0.008, 0.007, 0.95), true)

	var bench := full.grow(-18.0)
	draw_rect(bench, Color(0.105, 0.079, 0.052, 1.0), true)
	draw_rect(bench, Color(0.43, 0.31, 0.17, 0.78), false, 2.0)

	# Joined scavenged boards, with repeatable grain and old scoring marks.
	var plank_height := 76.0
	var y := bench.position.y + plank_height
	while y < bench.end.y:
		draw_line(Vector2(bench.position.x, y), Vector2(bench.end.x, y), Color(0.025, 0.018, 0.012, 0.74), 3.0)
		draw_line(Vector2(bench.position.x, y + 3.0), Vector2(bench.end.x, y + 3.0), Color(0.28, 0.19, 0.10, 0.35), 1.0)
		y += plank_height
	for index in range(18):
		var row := float(index % 6)
		var column := float(index / 6)
		var start := bench.position + Vector2(44.0 + column * bench.size.x * 0.29, 31.0 + row * 101.0)
		var length := 58.0 + float((index * 17) % 86)
		draw_line(start, start + Vector2(length, -5.0 + float(index % 3) * 4.0), Color(0.45, 0.30, 0.15, 0.22), 1.0)

	# The controls sit on top of these sheets; the exposed edges and binding
	# remain visible in the central gutter and outer margins.
	var pages := _page_rectangles(bench)
	for page in pages:
		_draw_page_shadow(page)
	_draw_binding(pages)
	_draw_tape(pages[0].position + Vector2(45.0, 7.0), -0.08)
	_draw_tape(Vector2(pages[1].end.x - 82.0, pages[1].position.y + 8.0), 0.07)

	for corner in [bench.position + Vector2(11, 11), Vector2(bench.end.x - 11, bench.position.y + 11), Vector2(bench.position.x + 11, bench.end.y - 11), bench.end - Vector2(11, 11)]:
		draw_circle(corner, 4.5, Color(0.20, 0.22, 0.19, 1.0))
		draw_line(corner - Vector2(2.5, 0.0), corner + Vector2(2.5, 0.0), Color(0.50, 0.48, 0.38, 0.72), 1.0)


func _page_rectangles(bench: Rect2) -> Array[Rect2]:
	var inset := 29.0
	var top := 78.0
	var gap := 22.0
	var available := Rect2(
		bench.position + Vector2(inset, top),
		bench.size - Vector2(inset * 2.0, top + inset)
	)
	if _vertical_pages:
		var half_height := (available.size.y - gap) * 0.5
		return [
			Rect2(available.position, Vector2(available.size.x, half_height)),
			Rect2(available.position + Vector2(0.0, half_height + gap), Vector2(available.size.x, half_height)),
		]
	var half_width := (available.size.x - gap) * 0.5
	return [
		Rect2(available.position, Vector2(half_width, available.size.y)),
		Rect2(available.position + Vector2(half_width + gap, 0.0), Vector2(half_width, available.size.y)),
	]


func _draw_page_shadow(page: Rect2) -> void:
	draw_rect(Rect2(page.position + Vector2(7.0, 9.0), page.size), Color(0.0, 0.0, 0.0, 0.45), true)
	draw_rect(page, Color(0.69, 0.63, 0.49, 0.38), true)
	draw_line(page.position + Vector2(18.0, 35.0), Vector2(page.position.x + 18.0, page.end.y - 24.0), Color(0.47, 0.20, 0.14, 0.24), 1.0)


func _draw_binding(pages: Array[Rect2]) -> void:
	if _vertical_pages:
		var y := (pages[0].end.y + pages[1].position.y) * 0.5
		for index in range(10):
			var x := lerpf(pages[0].position.x + 36.0, pages[0].end.x - 36.0, float(index) / 9.0)
			draw_line(Vector2(x, y - 9.0), Vector2(x, y + 9.0), Color(0.12, 0.13, 0.11, 0.94), 3.0)
		return
	var x := (pages[0].end.x + pages[1].position.x) * 0.5
	for index in range(12):
		var y := lerpf(pages[0].position.y + 34.0, pages[0].end.y - 34.0, float(index) / 11.0)
		draw_line(Vector2(x - 9.0, y), Vector2(x + 9.0, y), Color(0.12, 0.13, 0.11, 0.94), 3.0)


func _draw_tape(origin: Vector2, angle: float) -> void:
	var axis := Vector2(cos(angle), sin(angle))
	var normal := Vector2(-axis.y, axis.x)
	var half_length := 37.0
	var half_width := 9.0
	var points := PackedVector2Array([
		origin - axis * half_length - normal * half_width,
		origin + axis * half_length - normal * half_width,
		origin + axis * half_length + normal * half_width,
		origin - axis * half_length + normal * half_width,
	])
	draw_colored_polygon(points, Color(0.72, 0.64, 0.42, 0.54))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(0.37, 0.31, 0.18, 0.42), 1.0)

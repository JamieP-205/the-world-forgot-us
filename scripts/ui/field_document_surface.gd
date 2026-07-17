class_name FieldDocumentSurface
extends Control
## Shared physical surface for menus and records. It is deliberately drawn
## from simple print-shop shapes so every overlay reads as an object Ellie
## could carry, fold and repair, rather than a floating software dashboard.

@export_enum("Route sheet", "Archive file", "Incident report", "Field manual", "Menu sheet")
var document_kind := 0
@export var accent := Color(0.39, 0.56, 0.50, 0.82)
@export var paper_tint := Color(0.70, 0.67, 0.55, 1.0)
@export var show_receiver_rail := true
@export var show_tape := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x < 30.0 or size.y < 30.0:
		return
	var w := size.x
	var h := size.y
	var paper := Rect2(12.0, 10.0, w - 24.0, h - 20.0)

	# Blackened clipboard steel remains visible around the paper edge.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.055, 0.061, 0.055, 0.98))
	draw_rect(Rect2(4.0, 4.0, w - 8.0, h - 8.0), Color(0.12, 0.125, 0.108, 0.94), false, 2.0)
	for screw in [Vector2(8, 8), Vector2(w - 8, 8), Vector2(8, h - 8), Vector2(w - 8, h - 8)]:
		draw_circle(screw, 2.7, Color(0.37, 0.35, 0.28, 0.9))
		draw_line(screw + Vector2(-1.5, 0), screw + Vector2(1.5, 0), Color(0.08, 0.08, 0.07), 0.8)

	# A clipped polygon gives the sheet imperfect, handled corners.
	var sheet_points := PackedVector2Array([
		Vector2(paper.position.x + 5, paper.position.y),
		Vector2(paper.end.x - 2, paper.position.y + 1),
		Vector2(paper.end.x, paper.end.y - 7),
		Vector2(paper.end.x - 6, paper.end.y),
		Vector2(paper.position.x + 1, paper.end.y - 2),
		Vector2(paper.position.x, paper.position.y + 8),
	])
	draw_colored_polygon(sheet_points, paper_tint)

	# Fibres, water tide marks and old folds are restrained enough to stay
	# behind small type while making the page feel handled.
	for row in 22:
		var y := paper.position.y + 12.0 + float(row) * maxf(8.0, paper.size.y / 23.0)
		var wobble := sin(float(row) * 1.91 + float(document_kind)) * 1.4
		draw_line(
			Vector2(paper.position.x + 8.0, y),
			Vector2(paper.end.x - 8.0, y + wobble),
			Color(0.22, 0.23, 0.19, 0.035), 1.0
		)
	for stain in 5:
		var centre := Vector2(
			paper.position.x + paper.size.x * (0.16 + fmod(float(stain) * 0.223, 0.69)),
			paper.position.y + paper.size.y * (0.13 + fmod(float(stain) * 0.317, 0.72)),
		)
		draw_circle(centre, 18.0 + stain * 5.0, Color(0.21, 0.18, 0.12, 0.014))

	var fold_x := paper.position.x + paper.size.x * (0.61 if document_kind % 2 == 0 else 0.42)
	draw_line(Vector2(fold_x, paper.position.y + 4), Vector2(fold_x + 3, paper.end.y - 5), Color(0.27, 0.25, 0.19, 0.09), 1.0)
	draw_line(Vector2(fold_x + 2, paper.position.y + 4), Vector2(fold_x + 5, paper.end.y - 5), Color(0.92, 0.86, 0.68, 0.055), 1.0)

	if show_receiver_rail:
		_draw_receiver_rail(paper)
	if show_tape:
		_draw_tape(Vector2(paper.position.x + 20, paper.position.y - 3), -0.055)
		_draw_tape(Vector2(paper.end.x - 96, paper.end.y - 14), 0.035)


func _draw_receiver_rail(paper: Rect2) -> void:
	var rail := Rect2(paper.position.x + 7.0, paper.position.y + 44.0, 17.0, maxf(60.0, paper.size.y - 88.0))
	draw_rect(rail, Color(0.10, 0.14, 0.13, 0.88))
	draw_line(Vector2(rail.end.x + 3, rail.position.y), Vector2(rail.end.x + 3, rail.end.y), accent, 1.4)
	var meter := Rect2(rail.position.x + 3, rail.position.y + 9, 11, 42)
	draw_rect(meter, Color(0.65, 0.59, 0.43, 0.86))
	draw_line(meter.position + Vector2(5.5, 35), meter.position + Vector2(8.8, 11), Color(0.42, 0.17, 0.12, 0.9), 1.2)
	for slot in 7:
		var y := rail.end.y - 49.0 + slot * 6.0
		draw_line(Vector2(rail.position.x + 4, y), Vector2(rail.end.x - 4, y), Color(0.48, 0.53, 0.43, 0.55), 1.2)


func _draw_tape(origin: Vector2, skew: float) -> void:
	var tape := PackedVector2Array([
		origin,
		origin + Vector2(78.0, 2.0 + skew * 40.0),
		origin + Vector2(75.0, 19.0 + skew * 40.0),
		origin + Vector2(3.0, 17.0),
	])
	draw_colored_polygon(tape, Color(0.78, 0.72, 0.52, 0.42))
	draw_line(origin + Vector2(7, 5), origin + Vector2(69, 7 + skew * 40.0), Color(0.98, 0.93, 0.72, 0.12), 1.0)
